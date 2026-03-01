data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "keystone-infra-terraform-state"
    key    = "data/eu-north-1/data.tfstate"
    region = "eu-north-1"
  }
  workspace = terraform.workspace
}

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
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false

  database_subnets_count       = 2
  create_database_subnet_group = true

  enable_custom_nacls = false

  enable_s3_endpoint = true

  interface_endpoint_services = ["ecs", "ecr.api", "ecr.dkr"]
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
  certificate_arn = aws_acm_certificate_validation.alb.certificate_arn

  # Default target group — ECS tasks will register here
  target_group_port     = 5555
  target_group_protocol = "HTTP"
  target_type           = "ip" # Fargate uses awsvpc networking → ip targets

  health_check = {
    path    = "/"
    matcher = "200"
  }

  # Host-based routing — only matching domains reach the target group
  listener_rules = var.listener_rules
}


module "ecs_cluster" {
  source = "../modules/ecs-cluster"

  environment = var.environment
  project     = var.project

  enable_container_insights = true
}