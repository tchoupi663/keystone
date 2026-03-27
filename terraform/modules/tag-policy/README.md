# AWS Organizations Tag Policy Module

This module creates and manages an AWS Organizations tag policy to enforce consistent tagging across all AWS resources in the organization.

## Features

- Enforces mandatory tags: `Project`, `Environment`, `ManagedBy`
- Case-sensitive tag key enforcement
- Controlled values for `Environment` tag
- Blocks resource creation without required tags

## Prerequisites

- AWS Organizations enabled
- Running from the organization management account or a delegated administrator account
- Terraform AWS provider with Organizations permissions

## Usage

```hcl
module "tag_policy" {
  source = "../../modules/tag-policy"

  policy_name        = "keystone-mandatory-tags"
  policy_description = "Enforces mandatory tagging standards for Keystone project"
  
  enforce_project     = true
  enforce_environment = true
  enforce_managed_by  = true
  
  allowed_environments = ["dev", "staging", "preprod", "prod"]
  project_name         = "keystone"
  
  # Attach to specific OUs or accounts
  target_ids = [
    "ou-xxxx-xxxxxxxx",  # Replace with your OU ID
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `policy_name` | Name of the tag policy | `string` | n/a | yes |
| `policy_description` | Description of the tag policy | `string` | n/a | yes |
| `enforce_project` | Enforce Project tag | `bool` | `true` | no |
| `enforce_environment` | Enforce Environment tag | `bool` | `true` | no |
| `enforce_managed_by` | Enforce ManagedBy tag | `bool` | `true` | no |
| `allowed_environments` | List of allowed environment values | `list(string)` | `["dev", "staging", "prod"]` | no |
| `project_name` | Default project name | `string` | `"keystone"` | no |
| `target_ids` | List of OU or account IDs to attach the policy to | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `policy_id` | The ID of the created tag policy |
| `policy_arn` | The ARN of the created tag policy |

## Important Notes

1. **Testing**: Test tag policies in a non-production OU before applying organization-wide
2. **Exemptions**: Some AWS resources don't support tags - policy won't block these
3. **Existing Resources**: Policy only affects new resources; existing resources may be non-compliant
4. **Detachment**: Can take up to 24 hours for policy changes to fully propagate

## Validation

After applying, test policy enforcement:

```bash
# Attempt to create a resource without required tags (should fail)
aws ec2 create-security-group \
  --group-name test-sg \
  --description "Test SG" \
  --vpc-id vpc-xxxxx \
  --region eu-north-1
```

Expected error: Tag policy enforcement prevents resource creation without required tags.

## References

- [AWS Organizations Tag Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
