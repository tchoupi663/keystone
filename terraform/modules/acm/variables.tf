variable "domain_name" {
  description = "The domain name for the certificate"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, preprod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Region      = var.region
      ManagedBy   = "terraform"
      Module      = "acm"
    },
    var.tags
  )
}

variable "validation_record_fqdns" {
  description = "List of FQDNs for DNS validation records"
  type        = list(string)
  default     = []
}
