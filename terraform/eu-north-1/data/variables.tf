variable "region" {
  description = "Define the region"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Define the environment (dev, staging, prod)"
  type        = string
  # No default - must be explicitly provided via tfvars
}

variable "project" {
  description = "Define the project"
  type        = string
  default     = "keystone"
}

variable "snapshot_identifier" {
  description = "Restore RDS from this snapshot ID if provided"
  type        = string
  default     = null
}