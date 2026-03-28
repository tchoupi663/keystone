output "policy_id" {
  description = "The ID of the created tag policy"
  value       = aws_organizations_policy.tag_policy.id
}

output "policy_arn" {
  description = "The ARN of the created tag policy"
  value       = aws_organizations_policy.tag_policy.arn
}

output "policy_name" {
  description = "The name of the created tag policy"
  value       = aws_organizations_policy.tag_policy.name
}

output "attachment_ids" {
  description = "List of policy attachment IDs"
  value       = [for attachment in aws_organizations_policy_attachment.tag_policy_attachment : attachment.id]
}
