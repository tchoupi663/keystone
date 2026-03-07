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
  description = "Security group ID attached to the RDS instance"
  value       = module.rds.db_security_group_id
}
