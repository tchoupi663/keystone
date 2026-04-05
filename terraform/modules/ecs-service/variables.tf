# ──────────────────────────────────────────────
# Common
# ──────────────────────────────────────────────

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Region      = var.region
      ManagedBy   = "terraform"
      Module      = "ecs-service"
    },
    var.tags
  )
}


# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────

variable "vpc_id" {
  description = "ID of the VPC where ECS resources are deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where ECS tasks run (private subnets when using NAT)"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign a public IP to ECS tasks. Set to false when tasks run in private subnets behind NAT."
  type        = bool
  default     = false
}


# ──────────────────────────────────────────────
# Cloudflare Tunnel
# ──────────────────────────────────────────────

variable "cloudflare_tunnel_token_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Cloudflare Tunnel token"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}


# ──────────────────────────────────────────────
# RDS integration
# ──────────────────────────────────────────────

variable "rds_security_group_id" {
  description = "Security group ID of the RDS instance (ECS tasks will be allowed ingress)"
  type        = string
  default     = null
}

variable "db_host" {
  description = "RDS endpoint hostname (without port)"
  type        = string
  default     = null
}

variable "db_name" {
  description = "Name of the database to connect to"
  type        = string
  default     = null
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432
}

variable "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master user credentials"
  type        = string
  default     = null
}


# ──────────────────────────────────────────────
# Container / Task Definition
# ──────────────────────────────────────────────

variable "app_image" {
  description = "Full Docker image URI (e.g. 123456789.dkr.ecr.eu-north-1.amazonaws.com/app:latest). If null, uses the ECR repository created by this module."
  type        = string
}

variable "github_token_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing the GitHub Packages access token (JSON with username and password keys)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256 = 0.25 vCPU)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = string
  default     = "1024"
}


# ──────────────────────────────────────────────
# Health Check
# ──────────────────────────────────────────────

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual container."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, to wait when expecting a response from a health check."
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "The number of times to retry a failed health check before the container is considered unhealthy."
  type        = number
  default     = 3
}

variable "health_check_start_period" {
  description = "The optional grace period within which to provide containers time to bootstrap before failed health checks count towards the maximum number of retries."
  type        = number
  default     = 60
}


# ──────────────────────────────────────────────
# Service
# ──────────────────────────────────────────────

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster to deploy the service to"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec (SSM-based shell access into containers) — useful for debugging. WARNING: Should NEVER be set to true in production environments."
  type        = bool
  default     = false
}


# ──────────────────────────────────────────────
# Capacity provider
# ──────────────────────────────────────────────

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for the ECS service. When set, launch_type is omitted. Each object must have 'capacity_provider' and optionally 'weight' and 'base'."
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
  ]
}


# ──────────────────────────────────────────────
# Logging
# ──────────────────────────────────────────────

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}


# ──────────────────────────────────────────────
# Auto Scaling
# ──────────────────────────────────────────────

variable "enable_autoscaling" {
  description = "Enable auto-scaling for the ECS service"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks when auto-scaling is enabled"
  type        = number
  default     = 4
}

variable "cpu_scaling_target" {
  description = "Target CPU utilisation percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "memory_scaling_target" {
  description = "Target memory utilisation percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "scaling_scale_in_cooldown" {
  description = "The amount of time, in seconds, after a scale in activity completes before another scale in activity can start."
  type        = number
  default     = 300
}

variable "scaling_scale_out_cooldown" {
  description = "The amount of time, in seconds, after a scale out activity completes before another scale out activity can start."
  type        = number
  default     = 60
}


# ──────────────────────────────────────────────
# Sidecars
# ──────────────────────────────────────────────

variable "alloy_image_version" {
  description = "Grafana Alloy Docker image version"
  type        = string
  default     = "v1.14.2"
}

variable "cloudflared_image_version" {
  description = "Cloudflare Tunnel (cloudflared) Docker image version"
  type        = string
  default     = "2026.3.0"
}

# ── ADDED ─────────────────────────────────────────────────────────

variable "grafana_loki_host_ssm_arn" {
  description = "SSM ARN of the Grafana Cloud Loki host."
  type        = string
}

variable "grafana_loki_user_ssm_arn" {
  description = "SSM ARN of the Grafana Cloud Loki numeric user ID."
  type        = string
}

variable "grafana_loki_api_key_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret that holds the Grafana Cloud API key (the Loki basic-auth password). The secret value should be the raw API key string, not JSON."
  type        = string
}

variable "grafana_prometheus_url_ssm_arn" {
  description = "SSM ARN of the Grafana Cloud Prometheus remote-write URL."
  type        = string
}

variable "grafana_prometheus_user_ssm_arn" {
  description = "SSM ARN of the Grafana Cloud Prometheus numeric user ID."
  type        = string
}

variable "grafana_tempo_endpoint_ssm_arn" {
  description = "SSM ARN of the Grafana Cloud Tempo remote-write URL."
  type        = string
}

variable "grafana_tempo_user_ssm_arn" {
  description = "SSM ARN of the Grafana Cloud Tempo numeric user ID."
  type        = string
}



# ──────────────────────────────────────────────
# Scheduled Scaling
# ──────────────────────────────────────────────

variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling for the ECS service"
  type        = bool
  default     = false
}

variable "scale_down_cron" {
  description = "Cron expression for scaling down (e.g., '0 22 * * ? *' for 10 PM)"
  type        = string
  default     = "0 22 * * ? *"
}

variable "scale_up_cron" {
  description = "Cron expression for scaling up (e.g., '0 8 * * ? *' for 8 AM)"
  type        = string
  default     = "0 8 * * ? *"
}

variable "scale_down_min_capacity" {
  description = "Minimum capacity during scale down period"
  type        = number
  default     = 0
}

variable "scale_down_max_capacity" {
  description = "Maximum capacity during scale down period"
  type        = number
  default     = 0
}

variable "scale_up_min_capacity" {
  description = "Minimum capacity during scale up period"
  type        = number
  default     = 1
}

variable "scale_up_max_capacity" {
  description = "Maximum capacity during scale up period"
  type        = number
  default     = 4
}
