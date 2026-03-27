
output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_endpoint" {
  description = "Connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Hostname of the RDS instance (without port)"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database listens on"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the default database"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master password (only set when manage_master_user_password = true)"
  value       = var.manage_master_user_password ? aws_db_instance.this.master_user_secret[0].secret_arn : null
}

output "db_security_group_id" {
  description = "ID of the security group attached to the RDS instance"
  value       = aws_security_group.rds.id
}

output "rds_alarms_topic_arn" {
  description = "ARN of the SNS topic for RDS alarms"
  value       = var.enable_alarms ? aws_sns_topic.rds_alarms[0].arn : null
}
