# ──────────────────────────────────────────────
# ECS Service Outputs
# ──────────────────────────────────────────────

output "service_id" {
  description = "ID of the ECS service"
  value       = module.apps.service_id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.apps.service_name
}

# ──────────────────────────────────────────────
# Task Definition Outputs
# ──────────────────────────────────────────────

output "task_definition_arn" {
  description = "ARN of the current task definition"
  value       = module.apps.task_definition_arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = module.apps.task_definition_family
}

# ──────────────────────────────────────────────
# IAM Outputs
# ──────────────────────────────────────────────

output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.apps.execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.apps.task_role_arn
}

# ──────────────────────────────────────────────
# Logging Outputs
# ──────────────────────────────────────────────

output "log_group_name" {
  description = "Name of the CloudWatch log group for the ECS service"
  value       = module.apps.log_group_name
}
