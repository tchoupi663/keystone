# ──────────────────────────────────────────────
# Security Group — controls who can reach the DB
# ──────────────────────────────────────────────
# ECS tasks (or any workload) in the allowed CIDR blocks can connect.
# No egress rules are needed on the DB side.

resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-"
  description = "Allow inbound database traffic from ECS tasks SG only"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────────────────────────────────────
# RDS Instance
# ──────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-db"

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  port           = var.port

  # Sizing
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type

  # Networking
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # DB lives in isolated database subnets, never public

  # Credentials
  db_name  = var.db_name
  username = var.db_username

  # When true, RDS auto-creates and rotates the password in Secrets Manager.
  # When false, the caller must supply db_password.
  manage_master_user_password = var.manage_master_user_password
  password                    = var.manage_master_user_password ? null : var.db_password

  # Backup & Maintenance
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Availability & Protection
  multi_az            = var.multi_az
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null
    ? var.final_snapshot_identifier
    : "${var.project}-${var.environment}-db-final-snapshot"
  )

  # Encryption
  storage_encrypted = var.storage_encrypted

  # Monitoring
  performance_insights_enabled    = var.performance_insights_enabled
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Upgrades
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-db"
  })
}
