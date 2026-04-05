locals {
  cloudflare_ipv4 = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]

  # AWS VPC DNS Resolver is at the base CIDR + 2
  vpc_dns_resolver = "${cidrhost(var.vpc_cidr_block, 2)}/32"
}


# ECS Cluster

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-cluster"
  })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ──────────────────────────────────────────────
# ECS Security Group
# ──────────────────────────────────────────────

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.environment}-ecs-tasks-"
  description = "ECS tasks - outbound only (Cloudflare Tunnel handles inbound)"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow RDS access within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Allow HTTPS for AWS APIs and Cloudflare Tunnel"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow QUIC and TCP fallbacks for Cloudflare Tunnel"
    from_port   = 7844
    to_port     = 7844
    protocol    = "tcp"
    cidr_blocks = local.cloudflare_ipv4
  }

  egress {
    description = "Allow QUIC and TCP fallbacks for Cloudflare Tunnel"
    from_port   = 7844
    to_port     = 7844
    protocol    = "udp"
    cidr_blocks = local.cloudflare_ipv4
  }

  egress {
    description = "Allow DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [local.vpc_dns_resolver]
  }

  egress {
    description = "Allow DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.vpc_dns_resolver]
  }

  egress {
    description = "Allow NTP for clock sync"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-ecs-tasks-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
