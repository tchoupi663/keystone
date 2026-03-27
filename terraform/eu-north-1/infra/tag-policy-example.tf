# ──────────────────────────────────────────────
# Tag Policy Deployment Example
# ──────────────────────────────────────────────
# This is an OPTIONAL module for production environments
# to enforce tagging compliance via AWS Organizations.
#
# Prerequisites:
# 1. AWS Organizations must be enabled
# 2. Run from management account or delegated admin
# 3. Tag policies must be enabled in your organization:
#    aws organizations enable-policy-type \
#      --root-id r-xxxx \
#      --policy-type TAG_POLICY
#
# IMPORTANT: Test in a non-production OU first!
# ──────────────────────────────────────────────

# Uncomment and configure to deploy tag policy enforcement
/*
module "keystone_tag_policy" {
  source = "../../modules/tag-policy"

  policy_name        = "keystone-mandatory-tags"
  policy_description = "Enforces mandatory tagging standards for Keystone project across all accounts"
  
  # Enforcement flags
  enforce_project     = true
  enforce_environment = true
  enforce_managed_by  = true
  
  # Allowed values
  allowed_environments = ["dev", "staging", "preprod", "prod"]
  project_name         = "keystone"
  
  # Target OUs or Account IDs
  # Replace with your actual organizational unit ID(s)
  # Get OU IDs with: aws organizations list-organizational-units-for-parent --parent-id r-xxxx
  target_ids = [
    "ou-xxxx-xxxxxxxx",  # Development OU
    # "ou-yyyy-yyyyyyyy",  # Production OU (test in dev first!)
  ]

  tags = {
    Project     = "keystone"
    Environment = "org-wide"
    ManagedBy   = "terraform"
    Purpose     = "tag-compliance"
  }
}

output "tag_policy_id" {
  description = "ID of the deployed tag policy"
  value       = module.keystone_tag_policy.policy_id
}

output "tag_policy_arn" {
  description = "ARN of the deployed tag policy"
  value       = module.keystone_tag_policy.policy_arn
}
*/

# ──────────────────────────────────────────────
# Testing Tag Policy Enforcement
# ──────────────────────────────────────────────
# After deploying, test by attempting to create a
# resource without required tags. Example:
#
# aws ec2 run-instances \
#   --image-id ami-xxxxx \
#   --instance-type t3.micro \
#   --region eu-north-1
#
# Expected: Error due to missing required tags
#
# Correct command (with required tags):
# aws ec2 run-instances \
#   --image-id ami-xxxxx \
#   --instance-type t3.micro \
#   --region eu-north-1 \
#   --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=keystone},{Key=Environment,Value=dev},{Key=ManagedBy,Value=manual}]'
# ──────────────────────────────────────────────
