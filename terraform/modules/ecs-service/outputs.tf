# ──────────────────────────────────────────────
# ECS Service
# ──────────────────────────────────────────────

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.app.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}


# ──────────────────────────────────────────────
# Task Definition
# ──────────────────────────────────────────────

output "task_definition_arn" {
  description = "ARN of the current task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}





# ──────────────────────────────────────────────
# IAM
# ──────────────────────────────────────────────

output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}


# ──────────────────────────────────────────────
# CloudWatch
# ──────────────────────────────────────────────

output "log_group_name" {
  description = "Name of the CloudWatch log group for the ECS service"
  value       = aws_cloudwatch_log_group.app.name
}
