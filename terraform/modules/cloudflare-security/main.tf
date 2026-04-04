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
