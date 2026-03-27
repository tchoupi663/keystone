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

  snapshot_identifier = var.snapshot_identifier

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

# ──────────────────────────────────────────────
# Scheduled Scaling (Nightly Stop/Start)
# ──────────────────────────────────────────────

resource "aws_iam_role" "rds_scheduler" {
  count = var.enable_scheduled_scaling ? 1 : 0
  name  = "${var.project}-${var.environment}-rds-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rds-scheduler-role"
  })
}

resource "aws_iam_role_policy" "rds_scheduler" {
  count = var.enable_scheduled_scaling ? 1 : 0
  name  = "${var.project}-${var.environment}-rds-scheduler-policy"
  role  = aws_iam_role.rds_scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:StopDBInstance",
          "rds:StartDBInstance",
        ]
        Resource = [aws_db_instance.this.arn]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "stop_rds" {
  count = var.enable_scheduled_scaling ? 1 : 0
  name  = "${var.project}-${var.environment}-stop-rds"

  schedule_expression          = "cron(${var.scale_down_cron})"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.rds_scheduler[0].arn

    input = jsonencode({
      DbInstanceIdentifier = aws_db_instance.this.identifier
    })
  }
}

resource "aws_scheduler_schedule" "start_rds" {
  count = var.enable_scheduled_scaling ? 1 : 0
  name  = "${var.project}-${var.environment}-start-rds"

  schedule_expression          = "cron(${var.scale_up_cron})"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.rds_scheduler[0].arn

    input = jsonencode({
      DbInstanceIdentifier = aws_db_instance.this.identifier
    })
  }
}

# ──────────────────────────────────────────────
# Cross-Region Backup Replication
# ──────────────────────────────────────────────
# Automated snapshots can be copied to another region for disaster recovery.
# This uses AWS Backup to manage the cross-region copy lifecycle.

resource "aws_backup_vault" "primary" {
  count = var.enable_cross_region_backup ? 1 : 0
  name  = "${var.project}-${var.environment}-rds-backup-vault"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rds-backup-vault"
  })
}

# Provider configuration for DR region backup vault must be defined in calling module
# We only create the primary vault here; the selection and plan handle replication

resource "aws_backup_plan" "rds_cross_region" {
  count = var.enable_cross_region_backup ? 1 : 0
  name  = "${var.project}-${var.environment}-rds-cross-region-backup"

  rule {
    rule_name         = "daily-backup-with-cross-region-copy"
    target_vault_name = aws_backup_vault.primary[0].name
    schedule          = "cron(0 2 * * ? *)" # 02:00 UTC daily

    lifecycle {
      delete_after = var.backup_retention_period
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:${var.backup_replication_region}:${data.aws_caller_identity.current.account_id}:backup-vault/${var.project}-${var.environment}-rds-dr-vault"

      lifecycle {
        delete_after = var.backup_replication_retention_days
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rds-cross-region-backup"
  })
}

resource "aws_iam_role" "backup" {
  count = var.enable_cross_region_backup ? 1 : 0
  name  = "${var.project}-${var.environment}-rds-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rds-backup-role"
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.enable_cross_region_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  count      = var.enable_cross_region_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "rds" {
  count        = var.enable_cross_region_backup ? 1 : 0
  name         = "${var.project}-${var.environment}-rds-backup-selection"
  plan_id      = aws_backup_plan.rds_cross_region[0].id
  iam_role_arn = aws_iam_role.backup[0].arn

  resources = [
    aws_db_instance.this.arn
  ]
}

data "aws_caller_identity" "current" {}
