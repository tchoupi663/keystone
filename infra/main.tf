
module "vpc" {
  source = "../modules/vpc"

  region      = var.region
  environment = var.environment
  project     = var.project

  cidr_block = var.cidr_block

  public_subnets_count  = 2
  private_subnets_count = 2

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true
  connectivity_type       = "public"

  enable_internet_gateway = true
  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true

  database_subnets_count       = 2
  create_database_subnet_group = true

  enable_custom_nacls = false

  enable_s3_endpoint = true

  interface_endpoint_services = ["ecs"]
}


module "rds" {
  source = "../modules/rds"

  environment = var.environment
  project     = var.project
  region      = var.region

  # Networking ─ uses the DB subnet group created by the VPC module
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
  allowed_cidr_blocks  = [module.vpc.vpc_cidr_block] # ECS tasks in private subnets can reach the DB

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

  # Encryption & Monitoring
  storage_encrypted            = true
  performance_insights_enabled = true
}


module "alb" {
  source = "../modules/alb"

  environment = var.environment
  project     = var.project
  region      = var.region

  # Networking — ALB sits in public subnets, routes to ECS in private subnets
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
  vpc_cidr_block    = module.vpc.vpc_cidr_block

  # ALB Settings
  internal                   = false
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  # TLS — HTTP auto-redirects to HTTPS, unmatched hosts get 404
  certificate_arn = aws_acm_certificate.alb.arn

  # Default target group — ECS tasks will register here
  target_group_port     = 80
  target_group_protocol = "HTTP"
  target_type           = "ip" # Fargate uses awsvpc networking → ip targets

  health_check = {
    path    = "/"
    matcher = "200"
  }

  # Host-based routing — only matching domains reach the target group
  listener_rules = var.listener_rules
}