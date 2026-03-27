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

variable "skip_final_snapshot" {
  description = "Skip final snapshot when the DB is deleted (MUST be false for production)"
  type        = bool
  # No default - must be explicitly set per environment
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance (recommended true for production)"
  type        = bool
  # No default - must be explicitly set per environment
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability (recommended true for production)"
  type        = bool
  # No default - must be explicitly set per environment
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup replication for disaster recovery"
  type        = bool
  default     = false
}

variable "backup_replication_region" {
  description = "AWS region to replicate backups to for DR (e.g., eu-west-1)"
  type        = string
  default     = "eu-west-1"
}

variable "alarm_email_endpoints" {
  description = "List of email addresses to receive RDS alarm notifications"
  type        = list(string)
  default     = []
}
}