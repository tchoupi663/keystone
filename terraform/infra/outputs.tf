
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
# ALB
# ──────────────────────────────────────────────

output "alb_dns_name" {
  description = "DNS name of the ALB (point your domain here)"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route 53 alias records)"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.alb_arn
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB (reference in ECS task SG ingress rules)"
  value       = module.alb.alb_security_group_id
}

output "alb_target_group_arn" {
  description = "ARN of the default target group (attach ECS services here)"
  value       = module.alb.target_group_arn
}

output "alb_http_listener_arn" {
  description = "ARN of the HTTP listener (redirects to HTTPS)"
  value       = module.alb.http_listener_arn
}

output "alb_https_listener_arn" {
  description = "ARN of the HTTPS listener (default 404, host rules forward to targets)"
  value       = module.alb.https_listener_arn
}


# ──────────────────────────────────────────────
# ECS
# ──────────────────────────────────────────────

output "ecr_repository_url" {
  description = "ECR repository URL — push Docker images here"
  value       = module.ecs_cluster.ecr_repository_url
}

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
  value       = aws_security_group.ecs_tasks.id
}
