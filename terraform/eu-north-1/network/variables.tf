# Variables for network stack
# cloudflare_zone_id and cloudflare_account_id are now fetched from SSM

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
  default = [
    {
      action      = "block"
      description = "Leaked credential check"
      enabled     = true
      expression  = "(cf.waf.credential_check.password_leaked)"
      name        = "Leaked Credential Check"
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        mitigation_timeout  = 10
        period              = 10
        requests_per_period = 5
      }
    }
  ]
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
  default = [
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
      expression  = "(http.host eq \"edenkeystone.com\")"
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
    request_headers = [
      { id = "add_client_certificate_headers", enabled = true },
      { id = "add_visitor_location_headers", enabled = true },
      { id = "remove_visitor_ip_headers", enabled = true },
      { id = "add_waf_credential_check_status_header", enabled = true }
    ]
    response_headers = [
      { id = "remove_x-powered-by_header", enabled = true },
      { id = "add_security_headers", enabled = true }
    ]
  }
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
  default = [
    {
      action      = "off"
      description = "This policy excludes from inspection applications which are known to have desktop apps with certificate pinning."
      enabled     = true
      filters     = ["http"]
      name        = "Do Not Inspect"
      precedence  = 0
      traffic     = "any(app.type.ids[*] in {16})"
    },
    {
      action      = "block"
      description = "A catch-all policy to block all private traffic destined for the RFC1918 address space."
      enabled     = true
      filters     = ["l4"]
      name        = "Default deny for private traffic"
      precedence  = 10000
      traffic     = "net.dst.ip in {10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.96.0.0/12}"
      rule_settings = {
        notification_settings = {
          enabled = true
          msg     = "This connection has been blocked by your account default-deny network policy."
        }
      }
    }
  ]
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

variable "tunnel_origin_port" {
  description = "Internal port exposed by the application (used by cloudflared)"
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
