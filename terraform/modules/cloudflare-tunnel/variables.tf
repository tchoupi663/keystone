variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
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

variable "domain_name" {
  description = "Top-level domain name"
  type        = string
}

variable "subdomains" {
  description = "List of subdomains for the application"
  type        = list(string)
}

variable "tunnel_origin_port" {
  description = "Port the tunnel sidecar should connect to (internal app port)"
  type        = number
  default     = 8080
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Region      = var.region
      ManagedBy   = "terraform"
      Module      = "cloudflare-tunnel"
    },
    var.tags
  )
}
