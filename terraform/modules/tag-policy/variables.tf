variable "policy_name" {
  description = "Name of the tag policy"
  type        = string
}

variable "policy_description" {
  description = "Description of the tag policy"
  type        = string
}

variable "enforce_project" {
  description = "Enforce Project tag on all resources"
  type        = bool
  default     = true
}

variable "enforce_environment" {
  description = "Enforce Environment tag on all resources"
  type        = bool
  default     = true
}

variable "enforce_managed_by" {
  description = "Enforce ManagedBy tag on all resources"
  type        = bool
  default     = true
}

variable "allowed_environments" {
  description = "List of allowed values for Environment tag"
  type        = list(string)
  default     = ["dev", "staging", "preprod", "prod"]

  validation {
    condition     = length(var.allowed_environments) > 0
    error_message = "At least one environment must be specified"
  }
}

variable "project_name" {
  description = "Default project name for validation"
  type        = string
  default     = "keystone"
}

variable "target_ids" {
  description = "List of organizational unit IDs or AWS account IDs to attach the policy to"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the tag policy resource itself"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "tag-policy"
  }
}
