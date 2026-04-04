variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the ECS cluster"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where the cluster and tasks will reside"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group rules"
  type        = string
}
