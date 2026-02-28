
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