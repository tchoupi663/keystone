variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where flow logs will be enabled"
  type        = string
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_loki_host" {
  description = "Grafana Cloud Loki host for Firehose"
  type        = string
  default     = ""
}

variable "flow_logs_loki_user" {
  description = "Grafana user ID for Loki"
  type        = string
  default     = ""
}

variable "flow_logs_token" {
  description = "Grafana AWS token for Loki"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "vpc-flow-logs"
    },
    var.tags
  )
}
