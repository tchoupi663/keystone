locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  container_name = "${var.project}-${var.environment}-app"
}

# ──────────────────────────────────────────────
# Allow ECS Tasks → RDS (add ingress to RDS SG)
# ──────────────────────────────────────────────

resource "aws_security_group_rule" "rds_ingress_from_ecs" {
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
        # ── CHANGED: added fluent_bit log group so the sidecar can write its own meta-logs
        Resource = [
          "${aws_cloudwatch_log_group.app.arn}:*",
          "${aws_cloudwatch_log_group.fluent_bit.arn}:*"
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
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_read" {
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
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.secrets_read.arn
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

# ── ADDED: separate log group for Fluent Bit's own internal/meta logs
# Your app logs go to Grafana Loki; this captures Fluent Bit's own stderr
# (startup messages, plugin errors, etc.) so you can debug the sidecar itself.
resource "aws_cloudwatch_log_group" "fluent_bit" {
  name              = "/ecs/${var.project}-${var.environment}-fluent-bit"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-fluent-bit-logs"
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

    # ── TEMPORARILY DISABLED: Fluent Bit sidecar for debugging
    # {
    #   name  = "log_router"
    #   image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
    #   essential = true
    #   firelensConfiguration = {
    #     type = "fluentbit"
    #     options = {
    #       "enable-ecs-log-metadata" = "true"
    #     }
    #   }
    #   logConfiguration = {
    #     logDriver = "awslogs"
    #     options = {
    #       "awslogs-group"         = aws_cloudwatch_log_group.fluent_bit.name
    #       "awslogs-region"        = var.region
    #       "awslogs-stream-prefix" = "firelens"
    #     }
    #   }
    #   memory = 64
    # },

    # ── Your existing app container
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

      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_PORT", value = tostring(var.db_port) },
      ]

      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${var.db_master_user_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_master_user_secret_arn}:password::"
        }
      ]

      # ── TEMPORARILY DISABLED: awsfirelens (Loki) for debugging
      # logConfiguration = {
      #   logDriver = "awsfirelens"
      #   options = {
      #     Name           = "loki"
      #     Host           = var.grafana_loki_host
      #     port           = "443"
      #     tls            = "on"
      #     "tls.verify"   = "on"
      #     http_user      = var.grafana_loki_user
      #     line_format    = "json"
      #     # Static labels always attached to every log line in Grafana
      #     labels         = "job=${var.project},env=${var.environment},service=app"
      #   }
      #   secretOptions = [
      #     {
      #       # ECS resolves this from Secrets Manager and passes it to Fluent Bit
      #       # as the `http_passwd` config value (the Loki basic-auth password).
      #       name      = "http_passwd"
      #       valueFrom = var.grafana_loki_api_key_secret_arn
      #     }
      #   ]
      # }

      # ── TEMPORARY: standard awslogs for debugging
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # ── DISABLED for debugging
      # dependsOn = [
      #   {
      #     containerName = "log_router"
      #     condition     = "START"
      #   }
      # ]

      healthCheck = {
        command     = ["CMD-SHELL", "python -c 'import urllib.request; urllib.request.urlopen(\"http://localhost:${var.container_port}/\")'"]
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

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  health_check_grace_period_seconds = var.health_check_grace_period

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
