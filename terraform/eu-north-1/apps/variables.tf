
variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for the ECS service. Mutually exclusive with launch_type."
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

variable "image_tag" {
  description = "Tag of the image to deploy"
  type        = string
}

variable "app_image_repository" {
  description = "Docker image repository URI on GitHub Packages"
  type        = string
}

# ──────────────────────────────────────────────
# ECS Service configuration
# ──────────────────────────────────────────────

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

# ──────────────────────────────────────────────
# Health Check
# ──────────────────────────────────────────────

variable "health_check_interval" {
  description = "Time between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health check"
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 3
}

variable "health_check_start_period" {
  description = "Grace period for container health check at startup"
  type        = number
  default     = 60
}

# ──────────────────────────────────────────────
# Scaling
# ──────────────────────────────────────────────

variable "enable_autoscaling" {
  description = "Enable auto-scaling for the ECS service"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 3
}

variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling"
  type        = bool
  default     = false
}

variable "scale_down_cron" {
  description = "Cron expression for scaling down"
  type        = string
  default     = "0 23 * * ? *"
}

variable "scale_up_cron" {
  description = "Cron expression for scaling up"
  type        = string
  default     = "0 5 * * ? *"
}

variable "scale_down_min_capacity" {
  description = "Min capacity during scale down"
  type        = number
  default     = 0
}

variable "scale_down_max_capacity" {
  description = "Max capacity during scale down"
  type        = number
  default     = 0
}

variable "scale_up_min_capacity" {
  description = "Min capacity during scale up"
  type        = number
  default     = 1
}

variable "scale_up_max_capacity" {
  description = "Max capacity during scale up"
  type        = number
  default     = 3
}

