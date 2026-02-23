
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_rt" {
  value = module.vpc.public_rt
}

output "private_rt" {
  value = module.vpc.private_rt
}

output "nat_gateway_public" {
  value = module.vpc.nat_gateway_public
}
