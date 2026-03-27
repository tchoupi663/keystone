# ──────────────────────────────────────────────
# AWS Organizations Tag Policy
# ──────────────────────────────────────────────
# This module creates a tag policy to enforce
# consistent tagging across the AWS organization
# ──────────────────────────────────────────────

locals {
  # Build the tag policy JSON dynamically based on input variables
  tag_policy = {
    tags = merge(
      var.enforce_project ? {
        Project = {
          tag_key = {
            "@@assign" = "Project"
            "@@operators_allowed_for_child_policies" = ["@@none"]
          }
          tag_value = {
            "@@assign" = [var.project_name]
            "@@operators_allowed_for_child_policies" = ["@@append"]
          }
          enforced_for = {
            "@@assign" = ["*"]
          }
        }
      } : {},
      var.enforce_environment ? {
        Environment = {
          tag_key = {
            "@@assign" = "Environment"
            "@@operators_allowed_for_child_policies" = ["@@none"]
          }
          tag_value = {
            "@@assign" = var.allowed_environments
          }
          enforced_for = {
            "@@assign" = ["*"]
          }
        }
      } : {},
      var.enforce_managed_by ? {
        ManagedBy = {
          tag_key = {
            "@@assign" = "ManagedBy"
            "@@operators_allowed_for_child_policies" = ["@@none"]
          }
          tag_value = {
            "@@assign" = ["terraform", "manual", "cloudformation"]
          }
          enforced_for = {
            "@@assign" = ["*"]
          }
        }
      } : {}
    )
  }
}

# Tag Policy Resource
resource "aws_organizations_policy" "tag_policy" {
  name        = var.policy_name
  description = var.policy_description
  type        = "TAG_POLICY"

  content = jsonencode(local.tag_policy)

  tags = merge(
    var.tags,
    {
      Name = var.policy_name
    }
  )
}

# Attach policy to specified targets (OUs or accounts)
resource "aws_organizations_policy_attachment" "tag_policy_attachment" {
  for_each = toset(var.target_ids)

  policy_id = aws_organizations_policy.tag_policy.id
  target_id = each.value
}

# ──────────────────────────────────────────────
# Notes on Tag Policy Enforcement
# ──────────────────────────────────────────────
# 
# 1. Enforcement Level:
#    - "enforced_for": ["*"] applies to all resource types
#    - Can scope to specific resource types: ["ec2:instance", "s3:bucket"]
#
# 2. Allowed Values:
#    - "@@assign" replaces values (cannot override in child policies)
#    - "@@append" allows adding values in child policies
#
# 3. Case Sensitivity:
#    - Tag keys are case-sensitive
#    - "Environment" ≠ "environment"
#
# 4. Testing:
#    - Test in non-production OU first
#    - Verify using: aws organizations describe-effective-policy
#
# 5. Exemptions:
#    - Some resources don't support tags (CloudWatch log streams, etc.)
#    - Policy won't block creation of non-taggable resources
#
# ──────────────────────────────────────────────
