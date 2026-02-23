
module "vpc" {
  source = "../modules/vpc"

  region                = var.region
  environment           = var.environment
  cidr_block            = var.cidr_block
  public_subnets_count  = 2
  private_subnets_count = 2
  enable_nat_gateway    = true
  # single_nat_gateway    = false
  one_nat_gateway_per_az = true
}