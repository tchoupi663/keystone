
module "security" {
  source = "../../modules/security"

  environment = var.environment
  project     = var.project
  region      = var.region
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  region      = var.region
  environment = var.environment
  project     = var.project

  cidr_block = var.cidr_block

  public_subnets_count  = var.public_subnets_count
  private_subnets_count = var.private_subnets_count

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  map_public_ip_on_launch = var.map_public_ip_on_launch
  connectivity_type       = var.connectivity_type

  enable_internet_gateway = var.enable_internet_gateway

  # NAT enabled using cost-effective fck-nat instance
  enable_nat_gateway     = var.enable_nat_gateway
  nat_type               = var.nat_type
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  database_subnets_count       = var.database_subnets_count
  create_database_subnet_group = var.create_database_subnet_group

  enable_custom_nacls = var.enable_custom_nacls

  enable_s3_endpoint = var.enable_s3_endpoint

  interface_endpoint_services = var.interface_endpoint_services
}

module "vpc_flow_logs" {
  source = "../../modules/vpc-flow-logs"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  enable_flow_logs    = var.enable_flow_logs
  flow_logs_loki_host = data.aws_ssm_parameter.grafana_loki_host.value
  flow_logs_loki_user = data.aws_ssm_parameter.grafana_loki_user.value
  flow_logs_token     = data.aws_secretsmanager_secret_version.flow_logs_token.secret_string

  tags = var.tags
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment = var.environment
  project     = var.project
  region      = var.region

  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = var.cidr_block

  enable_container_insights = var.enable_container_insights
}