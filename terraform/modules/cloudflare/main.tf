# ──────────────────────────────────────────────
# DNS Records
# ──────────────────────────────────────────────

resource "cloudflare_dns_record" "subdomain_cnames" {
  for_each = toset(var.subdomains)

  content = "${cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id}.cfargotunnel.com"
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
  content = "${cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id}.cfargotunnel.com"
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

resource "cloudflare_zero_trust_tunnel_cloudflared" "keystone_dev" {
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

data "cloudflare_zero_trust_tunnel_cloudflared_token" "keystone_dev" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id

  # Ensure we fetch the token AFTER the tunnel resource is ready
  depends_on = [cloudflare_zero_trust_tunnel_cloudflared.keystone_dev]
}

resource "aws_secretsmanager_secret_version" "tunnel_token" {
  secret_id     = aws_secretsmanager_secret.tunnel_token.id
  secret_string = data.cloudflare_zero_trust_tunnel_cloudflared_token.keystone_dev.token
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "keystone_dev" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id

  config = {
    ingress = concat(
      [for s in var.subdomains : {
        hostname = "${s}.${var.domain_name}"
        service  = "http://localhost:8080"
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
    id           = null
    last_updated = "2026-03-28T16:18:00.906751Z"
    ref          = "779d4b8d34834b75a28723c643f42e43"
    version      = "1"
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
    id           = null
    last_updated = "2026-03-28T16:25:48.327768Z"
    ref          = "abb327a8219b4431be0e975ce32335b6"
    version      = "3"
  }]
}

resource "cloudflare_ruleset" "custom_waf" {
  kind    = "zone"
  name    = "Custom WAF Rules"
  phase   = "http_request_firewall_custom"
  zone_id = var.cloudflare_zone_id

  rules = [for r in coalesce(var.waf_custom_rules, []) : {
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
