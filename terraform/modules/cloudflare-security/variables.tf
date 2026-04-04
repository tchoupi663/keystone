variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
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

variable "waf_rate_limit_rules" {
  description = "Custom WAF Rate Limit Rules"
  type = list(object({
    name        = string
    action      = string
    enabled     = optional(bool, true)
    expression  = string
    description = optional(string, "")
    ratelimit = object({
      characteristics     = list(string)
      mitigation_timeout  = number
      period              = number
      requests_per_period = number
    })
  }))
  default = []
}

variable "waf_custom_rules" {
  description = "Custom WAF Firewall Rules"
  type = list(object({
    name        = string
    action      = string
    enabled     = optional(bool, true)
    expression  = string
    description = optional(string, "")
  }))
  default = []
}

variable "zero_trust_gateway_policy" {
  description = "Zero Trust Gateway Policies"
  type = list(object({
    name        = string
    description = string
    action      = string
    enabled     = optional(bool, true)
    filters     = list(string)
    traffic     = string
    precedence  = number
    rule_settings = optional(object({
      notification_settings = optional(object({
        enabled = bool
        msg     = string
      }))
    }))
  }))
  default = []
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Region      = var.region
      ManagedBy   = "terraform"
      Module      = "cloudflare-security"
    },
    var.tags
  )

  # Default WAF Custom Rules with dynamic domain interpolation
  default_waf_custom_rules = [
    {
      action      = "block"
      description = "Block /health endpoint"
      enabled     = true
      expression  = "(http.request.uri.path eq \"/health\")"
      name        = "Block Health Endpoint"
    },
    {
      action      = "block"
      description = "Block main domain"
      enabled     = false
      expression  = "(http.host eq \"${var.domain_name}\")"
      name        = "Block main domain"
    },
    {
      action      = "block"
      description = "Block common probes and scanners"
      enabled     = true
      expression  = "(http.request.uri.path contains \"/.env\") or (http.request.uri.path contains \"/.git\") or (http.request.uri.path contains \"/wp-\") or (http.request.uri.path contains \"/admin\") or (http.request.uri.path contains \"/config\") or (http.request.uri.path contains \"/setup\") or (http.request.uri.path contains \".php\") or (http.request.uri.path contains \"/login\")"
      name        = "Block Probes and Scanners"
    }
  ]
}
