# ──────────────────────────────────────────────
# DNS Records
# ──────────────────────────────────────────────

locals {
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

resource "cloudflare_dns_record" "subdomain_cnames" {
  for_each = toset(var.subdomains)

  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  name    = "${each.key}.${var.domain_name}"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

# Root DNS record — required so Cloudflare can catch and redirect it
resource "cloudflare_dns_record" "root" {
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  name    = var.domain_name
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

# ──────────────────────────────────────────────
# Cloudflare Tunnels
# ──────────────────────────────────────────────

resource "random_password" "tunnel_secret" {
  length  = 65
  special = false
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id    = var.cloudflare_account_id
  config_src    = "cloudflare"
  name          = "${var.project}-${var.environment}"
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
}

resource "aws_secretsmanager_secret" "tunnel_token" {
  name                    = "${var.project}/${var.environment}/cloudflare/tunnel-token"
  description             = "Cloudflare Tunnel Token for the ${var.project}-${var.environment} ECS sidecar"
  recovery_window_in_days = 7
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  # Ensure we fetch the token AFTER the tunnel resource is ready
  depends_on = [cloudflare_zero_trust_tunnel_cloudflared.this]
}

resource "aws_secretsmanager_secret_version" "tunnel_token" {
  secret_id     = aws_secretsmanager_secret.tunnel_token.id
  secret_string = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  config = {
    ingress = concat(
      [for s in var.subdomains : {
        hostname = "${s}.${var.domain_name}"
        service  = "http://localhost:${var.tunnel_origin_port}"
      }],
      [
        # Catch-all — required by cloudflared
        {
          service = "http_status:404"
        }
      ]
    )
  }
}

# ──────────────────────────────────────────────
# WAF & Rulesets
# ──────────────────────────────────────────────

resource "cloudflare_ruleset" "rate_limit_leaked_credentials" {
  kind    = "zone"
  name    = "default"
  phase   = "http_ratelimit"
  zone_id = var.cloudflare_zone_id

  rules = [for r in coalesce(var.waf_rate_limit_rules, []) : {
    action      = r.action
    description = r.description
    enabled     = r.enabled
    expression  = r.expression
    ratelimit = {
      characteristics     = r.ratelimit.characteristics
      mitigation_timeout  = r.ratelimit.mitigation_timeout
      period              = r.ratelimit.period
      requests_per_period = r.ratelimit.requests_per_period
    }
  }]
}

resource "cloudflare_ruleset" "http_to_https_redirect" {
  kind    = "zone"
  name    = "default"
  phase   = "http_request_dynamic_redirect"
  zone_id = var.cloudflare_zone_id
  rules = [{
    action = "redirect"
    action_parameters = {
      from_value = {
        preserve_query_string = false
        status_code           = 301
        target_url = {
          expression = "wildcard_replace(http.request.full_uri, r\"http://*\", r\"https://$${1}\")"
        }
      }
    }
    description  = "Redirect from HTTP to HTTPS"
    enabled      = true
    expression   = "(http.request.full_uri wildcard r\"http://*\")"
    }, {
    action = "redirect"
    action_parameters = {
      from_value = {
        preserve_query_string = true
        status_code           = 301
        target_url = {
          expression = "concat(\"https://${var.subdomains[0]}.${var.domain_name}\", http.request.uri.path)"
        }
      }
    }
    description  = "Redirect Root and WWW to Primary Subdomain"
    enabled      = true
    expression   = "(http.host eq \"${var.domain_name}\" or http.host eq \"www.${var.domain_name}\")"
  }]
}

resource "cloudflare_ruleset" "custom_waf" {
  kind    = "zone"
  name    = "Custom WAF Rules"
  phase   = "http_request_firewall_custom"
  zone_id = var.cloudflare_zone_id

  rules = [for r in concat(local.default_waf_custom_rules, coalesce(var.waf_custom_rules, [])) : {
    action      = r.action
    description = r.description
    enabled     = r.enabled
    expression  = r.expression
  }]
}

# ──────────────────────────────────────────────
# Cache
# ──────────────────────────────────────────────

resource "cloudflare_tiered_cache" "zone" {
  value   = coalesce(var.tiered_cache, "off")
  zone_id = var.cloudflare_zone_id
}

# ──────────────────────────────────────────────
# Page Rules
# ──────────────────────────────────────────────

resource "cloudflare_page_rule" "subdomain_browser_cache" {
  for_each = toset(var.subdomains)

  priority = 1
  status   = "active"
  target   = "${each.key}.${var.domain_name}/*"
  zone_id  = var.cloudflare_zone_id
  actions = {
    browser_cache_ttl = 86400
  }
}

# ──────────────────────────────────────────────
# Managed Transforms
# ──────────────────────────────────────────────

resource "cloudflare_managed_transforms" "zone" {
  zone_id = var.cloudflare_zone_id

  managed_request_headers = [for h in try(var.managed_transforms.request_headers, []) : {
    enabled = h.enabled
    id      = h.id
  }]

  managed_response_headers = [for h in try(var.managed_transforms.response_headers, []) : {
    enabled = h.enabled
    id      = h.id
  }]
}

# ──────────────────────────────────────────────
# Email Routing
# ──────────────────────────────────────────────

resource "cloudflare_email_routing_catch_all" "zone" {
  enabled = coalesce(var.email_routing_catch_all_enabled, false)
  zone_id = var.cloudflare_zone_id
  actions = [{
    type = "drop"
  }]
  matchers = [{
    type = "all"
  }]
}

# ──────────────────────────────────────────────
# Zero Trust Organization
# ──────────────────────────────────────────────

resource "cloudflare_zero_trust_organization" "account" {
  account_id                  = var.cloudflare_account_id
  allow_authenticate_via_warp = false
  auth_domain                 = "${split(".", var.domain_name)[0]}.cloudflareaccess.com"
  is_ui_read_only             = false
  name                        = "${split(".", var.domain_name)[0]}.cloudflareaccess.com"
  login_design                = {}
}

# ──────────────────────────────────────────────
# Zero Trust Access — Identity Providers
# ──────────────────────────────────────────────

resource "cloudflare_zero_trust_access_identity_provider" "otp" {
  account_id = var.cloudflare_account_id
  name       = "onetimepin"
  type       = "onetimepin"
  config     = {}
}

# ──────────────────────────────────────────────
# Zero Trust Access — mTLS Hostname Settings
# ──────────────────────────────────────────────

resource "cloudflare_zero_trust_access_mtls_hostname_settings" "account" {
  account_id = var.cloudflare_account_id
  settings   = []
}

# ──────────────────────────────────────────────
# Zero Trust Device Posture Rules
# ──────────────────────────────────────────────

resource "cloudflare_zero_trust_device_posture_rule" "gateway" {
  account_id = var.cloudflare_account_id
  name       = "Gateway"
  type       = "gateway"
}

resource "cloudflare_zero_trust_device_posture_rule" "warp" {
  account_id = var.cloudflare_account_id
  name       = "WARP"
  type       = "warp"
}

# ──────────────────────────────────────────────
# Zero Trust Gateway — Settings
# ──────────────────────────────────────────────

data "cloudflare_zero_trust_gateway_certificates" "account" {
  account_id = var.cloudflare_account_id
}

resource "cloudflare_zero_trust_gateway_settings" "account" {
  account_id = var.cloudflare_account_id
  settings = {
    certificate = {
      id = data.cloudflare_zero_trust_gateway_certificates.account.result[0].id
    }
    tls_decrypt = {
      enabled = true
    }
  }
}

# ──────────────────────────────────────────────
# Zero Trust Gateway — Policies
# ──────────────────────────────────────────────

resource "cloudflare_zero_trust_gateway_policy" "policies" {
  for_each   = { for p in coalesce(var.zero_trust_gateway_policy, []) : p.name => p }
  account_id = var.cloudflare_account_id

  action      = each.value.action
  description = each.value.description
  enabled     = each.value.enabled
  filters     = each.value.filters
  name        = each.value.name
  precedence  = each.value.precedence
  traffic     = each.value.traffic

  rule_settings = each.value.rule_settings != null ? {
    notification_settings = each.value.rule_settings.notification_settings != null ? {
      enabled = each.value.rule_settings.notification_settings.enabled
      msg     = each.value.rule_settings.notification_settings.msg
    } : null
  } : null
}
