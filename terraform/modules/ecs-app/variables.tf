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


# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────

variable "vpc_id" {
  description = "ID of the VPC where ECS resources are deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where ECS tasks run"
  type        = list(string)
}


# ──────────────────────────────────────────────
# ALB integration
# ──────────────────────────────────────────────

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (used as ingress source for ECS tasks)"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group to register ECS tasks with"
  type        = string
}


# ──────────────────────────────────────────────
# RDS integration
# ──────────────────────────────────────────────

variable "rds_security_group_id" {
  description = "Security group ID of the RDS instance (ECS tasks will be allowed ingress)"
  type        = string
}

variable "db_host" {
  description = "RDS endpoint hostname (without port)"
  type        = string
}

variable "db_name" {
  description = "Name of the database to connect to"
  type        = string
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432
}

variable "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master user credentials"
  type        = string
}


# ──────────────────────────────────────────────
# Container / Task Definition
# ──────────────────────────────────────────────

variable "app_image" {
  description = "Full Docker image URI (e.g. 123456789.dkr.ecr.eu-north-1.amazonaws.com/app:latest). If null, uses the ECR repository created by this module."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 5555
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = string
  default     = "512"
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

variable "health_check_grace_period" {
  description = "Seconds to wait before ALB health checks start after task launch"
  type        = number
  default     = 120
}

variable "enable_execute_command" {
  description = "Enable ECS Exec (SSM-based shell access into containers) — useful for debugging"
  type        = bool
  default     = true
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
