
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



output "rds_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS hostname (without port)"
  value       = module.rds.db_address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_port
}

output "rds_db_name" {
  description = "Name of the default database"
  value       = module.rds.db_name
}

output "rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master password"
  value       = module.rds.db_master_user_secret_arn
}

output "rds_security_group_id" {
  description = "Security group ID attached to the RDS instance (use in ECS task SG ingress rules)"
  value       = module.rds.db_security_group_id
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
  description = "ARN of the HTTP listener"
  value       = module.alb.http_listener_arn
}
