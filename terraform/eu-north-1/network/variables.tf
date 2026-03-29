variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for edenkeystone.com"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "keystone"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}
