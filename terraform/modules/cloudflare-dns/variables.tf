variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
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

variable "tunnel_id" {
  description = "The ID of the Cloudflare Tunnel to point DNS records to"
  type        = string
}

variable "tiered_cache" {
  description = "Tiered Cache value"
  type        = string
  default     = "off"
}

variable "email_routing_catch_all_enabled" {
  description = "Is Email Routing catch-all enabled?"
  type        = bool
  default     = false
}

variable "managed_transforms" {
  description = "Managed Request/Response Headers configuration"
  type = object({
    request_headers = list(object({
      id      = string
      enabled = bool
    }))
    response_headers = list(object({
      id      = string
      enabled = bool
    }))
  })
  default = {
    request_headers  = []
    response_headers = []
  }
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Region      = var.region
      ManagedBy   = "terraform"
      Module      = "cloudflare-dns"
    },
    var.tags
  )
}
