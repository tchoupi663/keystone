
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  description = "Allow HTTP/HTTPS inbound to ALB and outbound to VPC targets"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  # HTTPS
  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  # Egress to VPC targets (ECS tasks)
  egress {
    description     = "To ECS tasks on app port"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_http2               = var.enable_http2

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alb"
  })
}



resource "aws_lb_target_group" "default" {
  name                 = "app-tg"
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = var.health_check.enabled
    path                = var.health_check.path
    port                = var.health_check.port
    protocol            = var.health_check.protocol
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    timeout             = var.health_check.timeout
    interval            = var.health_check.interval
    matcher             = var.health_check.matcher
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}


# HTTP → always redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-http-listener"
  })
}


# HTTPS — default action is 404 (only matched hosts are forwarded)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 — unknown host"
      status_code  = "404"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-https-listener"
  })
}


# Block rules - explicitly return 403 for specific paths
resource "aws_lb_listener_rule" "blocked_paths" {
  count = length(var.blocked_paths) > 0 ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "403 - Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = var.blocked_paths
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rule-blocked-paths"
  })
}

# Host-based listener rules — forward traffic only for matching domains
resource "aws_lb_listener_rule" "host_based" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }

  condition {
    host_header {
      values = each.value.host_headers
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rule-${each.key}"
  })
}


