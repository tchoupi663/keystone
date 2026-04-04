
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

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}


# ──────────────────────────────────────────────
# ECS
# ──────────────────────────────────────────────

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = module.ecs_cluster.ecs_tasks_sg_id
}
