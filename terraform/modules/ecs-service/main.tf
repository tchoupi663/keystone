locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  container_name = "${var.project}-${var.environment}-app"

  alloy_config_b64 = base64encode(<<-EOT
    logging {
      level  = "debug"
      format = "logfmt"
    }

    prometheus.scrape "flask_app" {
      targets = [
        {"__address__" = "localhost:${var.container_port}"},
      ]
      forward_to = [prometheus.remote_write.grafana_cloud.receiver]
      scrape_interval = "60s"
    }

    prometheus.remote_write "grafana_cloud" {
      endpoint {
        url = "${var.grafana_prometheus_url}"
        basic_auth {
          username = "${var.grafana_prometheus_user}"
          password = coalesce(sys.env("GRAFANA_API_KEY"), "missing")
        }
        
        queue_config {
          max_samples_per_send = 1000
          batch_send_deadline  = "30s"
        }
      }
    }

    otelcol.receiver.otlp "otlp_receiver" {
      grpc {
        endpoint = "0.0.0.0:4317"
      }
      http {
        endpoint = "0.0.0.0:4318"
      }

      output {
        traces = [otelcol.processor.transform.add_peer_service.input]
        logs   = [otelcol.exporter.loki.grafanacloud.input]
      }
    }

    otelcol.processor.transform "add_peer_service" {
      error_mode = "ignore"
      trace_statements {
        context = "span"
        statements = [
          "set(span.attributes[\"peer.service\"], span.attributes[\"db.system\"]) where span.attributes[\"peer.service\"] == nil and span.attributes[\"db.system\"] != nil",
        ]
      }
      output {
        traces = [
          otelcol.exporter.otlp.grafanacloud.input,
          otelcol.connector.servicegraph.default.input,
        ]
      }
    }

    loki.write "grafanacloud" {
      endpoint {
        url = "https://${var.grafana_loki_host}/loki/api/v1/push"
        basic_auth {
          username = "${var.grafana_loki_user}"
          password = coalesce(sys.env("GRAFANA_API_KEY"), "missing")
        }
      }
      external_labels = {
        job = "keystone-app",
        env = "${var.environment}",
      }
    }

    otelcol.exporter.loki "grafanacloud" {
      forward_to = [loki.write.grafanacloud.receiver]
    }

    otelcol.connector.servicegraph "default" {
      dimensions = ["http.method", "http.target"]
      output {
        metrics = [otelcol.exporter.prometheus.servicegraphs.input]
      }
    }

    otelcol.exporter.prometheus "servicegraphs" {
      forward_to = [prometheus.remote_write.grafana_cloud.receiver]
      add_metric_suffixes = false
    }

    otelcol.exporter.otlp "grafanacloud" {
      client {
        endpoint = "${var.grafana_tempo_endpoint}"
        auth     = otelcol.auth.basic.grafanacloud.handler
      }
    }

    otelcol.auth.basic "grafanacloud" {
      username = "${var.grafana_tempo_user}"
      password = coalesce(sys.env("GRAFANA_API_KEY"), "missing")
    }
  EOT
  )
}

# ──────────────────────────────────────────────
# Allow ECS Tasks → RDS (add ingress to RDS SG)
# ──────────────────────────────────────────────

resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  count                    = var.rds_security_group_id != null ? 1 : 0
  type                     = "ingress"
  description              = "Allow ECS tasks to connect to RDS"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.ecs_security_group_id
  security_group_id        = var.rds_security_group_id
}


# ──────────────────────────────────────────────
# IAM — Task Execution Role (used by ECS agent)
# ──────────────────────────────────────────────

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ecs-execution-role"
  })
}

resource "aws_iam_role_policy" "ecs_execution" {
  name = "${var.project}-${var.environment}-ecs-execution"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMAuth"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [var.github_token_secret_arn]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        # ── CHANGED: removed fluent_bit from log groups
        Resource = [
          "${aws_cloudwatch_log_group.app.arn}:*",
          "${aws_cloudwatch_log_group.alloy.arn}:*",
          "${aws_cloudwatch_log_group.cloudflared.arn}:*"
        ]
      },
      # ── ADDED: allow execution role to resolve the Grafana API key at container startup
      # This is needed because the key is passed via `secretOptions` in logConfiguration,
      # which ECS resolves using the *execution* role (not the task role).
      {
        Sid    = "GrafanaSecret"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [var.grafana_loki_api_key_secret_arn]
      },
      {
        Sid    = "CloudflareTunnelToken"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [var.cloudflare_tunnel_token_secret_arn]
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_read" {
  count       = var.db_master_user_secret_arn != null ? 1 : 0
  name        = "${var.project}-${var.environment}-ecs-secrets-read"
  description = "Allow ECS execution role to read RDS credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.db_master_user_secret_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_secrets" {
  count      = var.db_master_user_secret_arn != null ? 1 : 0
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.secrets_read[0].arn
}


# ──────────────────────────────────────────────
# IAM — Task Role (used by the app container itself)
# ──────────────────────────────────────────────

resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ecs-task-role"
  })
}

resource "aws_iam_role_policy" "ecs_exec" {
  count = var.enable_execute_command ? 1 : 0
  name  = "${var.project}-${var.environment}-ecs-exec"
  role  = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}


# ──────────────────────────────────────────────
# CloudWatch Log Groups
# ──────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project}-${var.environment}-app"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ecs-logs"
  })
}

resource "aws_cloudwatch_log_group" "alloy" {
  name              = "/ecs/${var.project}-${var.environment}-alloy"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alloy-logs"
  })
}

resource "aws_cloudwatch_log_group" "cloudflared" {
  name              = "/ecs/${var.project}-${var.environment}-cloudflared"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-cloudflared-logs"
  })
}


# ──────────────────────────────────────────────
# ECS Task Definition
# ──────────────────────────────────────────────

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.environment}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([

    # ── Grafana Alloy sidecar for Prometheus metrics
    {
      name  = "alloy"
      image = "grafana/alloy:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "alloy"
        }
      }

      memory = 128

      environment = [
        { name = "ALLOY_CONFIG_B64", value = local.alloy_config_b64 }
      ]
      
      secrets = [
        {
          name      = "GRAFANA_API_KEY"
          valueFrom = var.grafana_loki_api_key_secret_arn
        }
      ]

      entryPoint = ["/bin/sh", "-c"]
      command    = ["echo \"$ALLOY_CONFIG_B64\" | base64 -d > /tmp/config.alloy && /bin/alloy run /tmp/config.alloy"]
    },

    # ── cloudflared sidecar — establishes an outbound tunnel to Cloudflare
    {
      name      = "cloudflared"
      image     = "cloudflare/cloudflared:latest"
      essential = true

      entryPoint = ["cloudflared"]
      command    = ["tunnel", "--no-autoupdate", "run", "--protocol", "http2"]

      linuxParameters = {
        initProcessEnabled = true
      }

      # Allows the non-root user (GID 65532) to use ICMP
      systemControls = [
        {
          namespace = "net.ipv4.ping_group_range"
          value     = "0 65535"
        }
      ]

      secrets = [
        {
          name      = "TUNNEL_TOKEN"
          valueFrom = var.cloudflare_tunnel_token_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cloudflared.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "cloudflared"
        }
      }

      memory = 128
    },

    # ── Application container
    {
      name      = local.container_name
      image     = var.app_image
      essential = true
      repositoryCredentials = {
        credentialsParameter = var.github_token_secret_arn
      }

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = flatten([
        [],
        var.db_host != null ? [
          { name = "DB_HOST", value = var.db_host },
          { name = "DB_NAME", value = var.db_name },
          { name = "DB_PORT", value = tostring(var.db_port) }
        ] : []
      ])

      secrets = flatten([
        [],
        var.db_master_user_secret_arn != null ? [
          {
            name      = "DB_USER"
            valueFrom = "${var.db_master_user_secret_arn}:username::"
          },
          {
            name      = "DB_PASSWORD"
            valueFrom = "${var.db_master_user_secret_arn}:password::"
          }
        ] : []
      ])

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-task-def"
  })
}


# ──────────────────────────────────────────────
# ECS Service
# ──────────────────────────────────────────────

resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.environment}-app"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = length(var.capacity_provider_strategy) == 0 ? "FARGATE" : null

  force_new_deployment = true

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ecs-service"
  })
}


# ──────────────────────────────────────────────
# Auto Scaling (unchanged)
# ──────────────────────────────────────────────

resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.project}-${var.environment}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_scaling_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.project}-${var.environment}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_scaling_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ──────────────────────────────────────────────
# Scheduled Scaling
# ──────────────────────────────────────────────

resource "aws_appautoscaling_scheduled_action" "scale_down" {
  count = var.enable_autoscaling && var.enable_scheduled_scaling && var.scale_down_cron != "" ? 1 : 0

  name               = "${var.project}-${var.environment}-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  schedule           = "cron(${var.scale_down_cron})"

  scalable_target_action {
    min_capacity = var.scale_down_min_capacity
    max_capacity = var.scale_down_max_capacity
  }
}

resource "aws_appautoscaling_scheduled_action" "scale_up" {
  count = var.enable_autoscaling && var.enable_scheduled_scaling && var.scale_up_cron != "" ? 1 : 0

  name               = "${var.project}-${var.environment}-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  schedule           = "cron(${var.scale_up_cron})"

  scalable_target_action {
    min_capacity = var.scale_up_min_capacity
    max_capacity = var.scale_up_max_capacity
  }
}
