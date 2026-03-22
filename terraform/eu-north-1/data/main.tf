data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "keystone-infra-terraform-state"
    key    = "infra/eu-north-1/infra.tfstate"
    region = "eu-north-1"
  }
  workspace = terraform.workspace
}

module "rds" {
  source = "../../modules/rds"

  environment = var.environment
  project     = var.project
  region      = var.region

  # Networking ─ uses the DB subnet group created by the VPC module
  vpc_id               = data.terraform_remote_state.infra.outputs.vpc_id
  db_subnet_group_name = data.terraform_remote_state.infra.outputs.database_subnet_group_name

  # Engine
  engine         = "postgres"
  engine_version = "16"
  port           = 5432

  # Smallest instance ─ 20 GB gp3
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  # Credentials ─ RDS manages the password in Secrets Manager
  db_name                     = "appdb"
  db_username                 = "dbadmin"
  manage_master_user_password = true

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"

  # Availability (single-AZ to keep costs low in dev)
  multi_az            = false # true
  deletion_protection = false
  skip_final_snapshot = true

  snapshot_identifier = var.snapshot_identifier

  # Encryption & Monitoring
  storage_encrypted            = true
  performance_insights_enabled = false

  # Scheduled Scaling (Nightly Stop/Start)
  # ECS stops at 20:00, starts at 07:00
  # RDS stops at 20:15, starts at 06:45 to wrap the ECS schedule
  enable_scheduled_scaling = true
  scale_down_cron          = "15 20 * * ? *"
  scale_up_cron            = "45 6 * * ? *"
}