# ──────────────────────────────────────────────
# Security Group — controls inbound access to the ALB
# ──────────────────────────────────────────────

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

  # Egress to VPC targets (ECS tasks in private subnets)
  egress {
    description = "All traffic to VPC targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────────────────────────────────────
# Application Load Balancer
# ──────────────────────────────────────────────

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

# ──────────────────────────────────────────────
# Default Target Group — ECS services will register here
# ──────────────────────────────────────────────

resource "aws_lb_target_group" "default" {
  name                 = "${var.project}-${var.environment}-tg"
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

# ──────────────────────────────────────────────
# HTTP Listener (port 80)
# ──────────────────────────────────────────────
# When HTTPS is enabled and redirect is on: redirects to 443
# Otherwise: forwards to the default target group

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https && var.http_to_https_redirect ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https && var.http_to_https_redirect ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.default.arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-http-listener"
  })
}

# ──────────────────────────────────────────────
# HTTPS Listener (port 443) — optional
# ──────────────────────────────────────────────

resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-https-listener"
  })
}
