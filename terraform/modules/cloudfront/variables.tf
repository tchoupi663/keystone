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
      Module      = "cloudfront"
    },
    var.tags
  )
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name to serve via CloudFront"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB Origin DNS Name"
  type        = string
}

variable "acm_certificate_arn" {
  description = "Global ACM Certificate ARN (us-east-1)"
  type        = string
}
