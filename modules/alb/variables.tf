
variable "environment" {
  description = "Environment name (dev, staging, prod, preprod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "preprod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, preprod"
  }
}

variable "project" {
  description = "Project name for tagging and resource identification"
  type        = string
  default     = "keystone"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "Define the region"
  type        = string
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
      Module      = "alb"
    },
    var.tags
  )
}

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────

variable "vpc_id" {
  description = "ID of the VPC where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be placed (minimum 2 in different AZs)"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets in different AZs are required for an ALB"
  }
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC (used for ALB egress to targets)"
  type        = string
}

# ──────────────────────────────────────────────
# ALB Settings
# ──────────────────────────────────────────────

variable "internal" {
  description = "If true, the ALB is internal (not internet-facing)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Prevent accidental deletion of the ALB"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "drop_invalid_header_fields" {
  description = "Drop HTTP headers with invalid header fields (security best practice)"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the ALB"
  type        = bool
  default     = true
}

# ──────────────────────────────────────────────
# Listener Configuration
# ──────────────────────────────────────────────

variable "enable_https" {
  description = "Enable the HTTPS listener on port 443 (requires certificate_arn)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener (required when enable_https = true)"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "http_to_https_redirect" {
  description = "Redirect HTTP traffic to HTTPS (only effective when enable_https = true)"
  type        = bool
  default     = true
}

# ──────────────────────────────────────────────
# Target Group
# ──────────────────────────────────────────────

variable "target_group_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda). Use 'ip' for ECS Fargate tasks"
  type        = string
  default     = "ip"
}

variable "deregistration_delay" {
  description = "Time in seconds to wait before deregistering a target (allows in-flight requests to complete)"
  type        = number
  default     = 30
}

variable "health_check" {
  description = "Health check configuration for the target group"
  type = object({
    enabled             = optional(bool, true)
    path                = optional(string, "/")
    port                = optional(string, "traffic-port")
    protocol            = optional(string, "HTTP")
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
    timeout             = optional(number, 5)
    interval            = optional(number, 30)
    matcher             = optional(string, "200")
  })
  default = {}
}

# ──────────────────────────────────────────────
# Access Logs
# ──────────────────────────────────────────────

variable "enable_access_logs" {
  description = "Enable ALB access logs to S3"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (required when enable_access_logs = true)"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 key prefix for ALB access logs"
  type        = string
  default     = "alb-logs"
}

# ──────────────────────────────────────────────
# Ingress Configuration
# ──────────────────────────────────────────────

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB (defaults to the entire internet)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
