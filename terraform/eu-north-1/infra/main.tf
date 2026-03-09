
module "vpc" {
  source = "../../modules/vpc"

  region      = var.region
  environment = var.environment
  project     = var.project

  cidr_block = var.cidr_block

  public_subnets_count  = var.public_subnets_count
  private_subnets_count = var.private_subnets_count

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true
  connectivity_type       = "public"

  enable_internet_gateway = true
  enable_nat_gateway      = true
  nat_type                = "instance"
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false

  database_subnets_count       = var.database_subnets_count
  create_database_subnet_group = true

  enable_custom_nacls = true

  enable_s3_endpoint = true

  interface_endpoint_services = []
}

module "dns" {
  source = "../../modules/dns"

  domain_name               = var.domain_name
  domain_validation_options = module.acm.domain_validation_options
  alb_dns_name              = module.alb.alb_dns_name
  alb_zone_id               = module.alb.alb_zone_id
}

module "acm" {
  source = "../../modules/acm"

  domain_name             = var.domain_name
  environment             = var.environment
  project                 = var.project
  validation_record_fqdns = module.dns.validation_record_fqdns
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.environment}-ecs-tasks-"
  description = "Allow inbound from ALB only, outbound to internet"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow RDS access within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    description = "Allow HTTPS for AWS APIs (ECR, CloudWatch, S3, etc.)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project}-${var.environment}-alb-logs-${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

module "alb" {
  source = "../../modules/alb"

  environment = var.environment
  project     = var.project
  region      = var.region
  domain_name = var.domain_name

  # Networking — ALB sits in public subnets, routes to ECS in private subnets
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
  vpc_cidr_block    = module.vpc.vpc_cidr_block

  # ALB Settings
  internal                   = false
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  # TLS — HTTP auto-redirects to HTTPS, unmatched hosts get 404
  certificate_arn = module.acm.certificate_arn

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

  ecs_sg_id = aws_security_group.ecs_tasks.id

  enable_access_logs = true
  access_logs_bucket = aws_s3_bucket.alb_logs.bucket
  access_logs_prefix = "alb-logs"

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# Ingress rule added after module.alb to break the circular SG reference:
# ECS SG cannot reference ALB SG inline (and vice-versa), so we use a separate rule resource.
resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  description              = "Allow traffic from ALB on app port"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.alb.alb_security_group_id
  security_group_id        = aws_security_group.ecs_tasks.id
}


module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment = var.environment
  project     = var.project

  enable_container_insights = true
}