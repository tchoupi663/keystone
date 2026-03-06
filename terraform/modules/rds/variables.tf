
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
      Module      = "rds"
    },
    var.tags
  )
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be created"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group (created by the VPC module)"
  type        = string
}

variable "engine" {
  description = "Database engine (e.g. postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Major version of the database engine (e.g. 16 for PostgreSQL 16)"
  type        = string
  default     = "16"
}

variable "port" {
  description = "Port the database listens on (5432 for postgres, 3306 for mysql)"
  type        = number
  default     = 5432
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t3.micro, db.t4g.micro)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password via Secrets Manager (recommended). When true, db_password is ignored."
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Master password (only used when manage_master_user_password = false). Must be >= 8 characters."
  type        = string
  default     = null
  sensitive   = true
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 to disable)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily time range (UTC) for automated backups, must not overlap with maintenance_window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly time range (UTC) for system maintenance"
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when the DB is deleted (set false in production)"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Name of the final snapshot (required when skip_final_snapshot = false)"
  type        = string
  default     = null
}

variable "storage_encrypted" {
  description = "Enable encryption at rest (uses default aws/rds KMS key)"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights (free tier on db.t3/t4g.micro)"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (e.g. [\"postgresql\", \"upgrade\"] for postgres)"
  type        = list(string)
  default     = []
}

variable "auto_minor_version_upgrade" {
  description = "Automatically apply minor engine upgrades during the maintenance window"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Allow major engine version upgrades (requires manual apply)"
  type        = bool
  default     = false
}
