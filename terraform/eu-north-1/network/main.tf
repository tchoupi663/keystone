locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────────
# DNS Records
# ──────────────────────────────────────────────

resource "cloudflare_dns_record" "demo_cname" {
  content = "${cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id}.cfargotunnel.com"
  name    = "demo.edenkeystone.com"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "root_cname" {
  content = "${cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id}.cfargotunnel.com"
  name    = "edenkeystone.com"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "www_cname" {
  content = "${cloudflare_zero_trust_tunnel_cloudflared.keystone_dev.id}.cfargotunnel.com"
  name    = "www.edenkeystone.com"
  proxied = true
  tags    = []
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
  recovery_window_in_days = 0 
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
    ingress = [
      {
        hostname = "demo.edenkeystone.com"
        service  = "http://localhost:8080"
      },
      {
        hostname = "edenkeystone.com"
        service  = "http://localhost:8080"
      },
      {
        hostname = "www.edenkeystone.com"
        service  = "http://localhost:8080"
      },
      # Catch-all — required by cloudflared
      {
        service = "http_status:404"
      }
    ]
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
  rules = [{
    action       = "block"
    description  = "Leaked credential check"
    enabled      = true
    expression   = "(cf.waf.credential_check.password_leaked)"
    id           = null
    last_updated = "2026-03-24T19:48:24.795548Z"
    ratelimit = {
      characteristics     = ["ip.src", "cf.colo.id"]
      mitigation_timeout  = 10
      period              = 10
      requests_per_period = 5
    }
    ref     = "392a0b3821d44ac694fe43628e3bffbb"
    version = "1"
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
          expression = "concat(\"https://demo.edenkeystone.com\", http.request.uri.path)"
        }
      }
    }
    description  = "Redirect to a different domain"
    enabled      = true
    expression   = "(http.host in {\"edenkeystone.com\" \"www.edenkeystone.com\"})"
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
  rules = [{
    action       = "block"
    description  = "Block /health endpoint"
    enabled      = true
    expression   = "(http.request.uri.path eq \"/health\")"
    id           = null
    last_updated = "2026-03-25T20:22:24.595069Z"
    ref          = "b0bcfb27e837440291486fb70d606210"
    version      = "1"
    }, {
    action       = "block"
    description  = "Block main domain"
    enabled      = false
    expression   = "(http.host eq \"edenkeystone.com\")"
    id           = null
    last_updated = "2026-03-28T16:17:31.539009Z"
    ref          = "3c95b139263d47ceaed32eff90ee2a80"
    version      = "2"
    }, {
    action       = "block"
    description  = "Block common probes and scanners"
    enabled      = true
    expression   = "(http.request.uri.path contains \"/.env\") or (http.request.uri.path contains \"/.git\") or (http.request.uri.path contains \"/wp-\") or (http.request.uri.path contains \"/admin\") or (http.request.uri.path contains \"/config\") or (http.request.uri.path contains \"/setup\") or (http.request.uri.path contains \".php\")"
    id           = null
    last_updated = "2026-03-28T16:37:23.618716Z"
    ref          = "305e9828d2c0403ebcba8248d49588a7"
    version      = "2"
  }]
}

# ──────────────────────────────────────────────
# Certificate
# ──────────────────────────────────────────────
# Note: Universal SSL is managed automatically by Cloudflare at the zone level.
# Explicit cloudflare_certificate_pack resources are for the paid Advanced Certificate Manager.

# ──────────────────────────────────────────────
# Cache
# ──────────────────────────────────────────────

resource "cloudflare_tiered_cache" "zone" {
  value   = "off"
  zone_id = var.cloudflare_zone_id
}

# ──────────────────────────────────────────────
# Page Rules
# ──────────────────────────────────────────────

resource "cloudflare_page_rule" "demo_browser_cache" {
  priority = 1
  status   = "active"
  target   = "demo.edenkeystone.com/*"
  zone_id  = var.cloudflare_zone_id
  actions = {
    browser_cache_ttl = 86400
  }
}

# ──────────────────────────────────────────────
# Managed Transforms (Request/Response Headers)
# ──────────────────────────────────────────────

resource "cloudflare_managed_transforms" "zone" {
  zone_id = var.cloudflare_zone_id
  managed_request_headers = [{
    enabled = true
    id      = "add_client_certificate_headers"
    }, {
    enabled = true
    id      = "add_visitor_location_headers"
    }, {
    enabled = true
    id      = "remove_visitor_ip_headers"
    }, {
    enabled = true
    id      = "add_waf_credential_check_status_header"
  }]
  managed_response_headers = [{
    enabled = false
    id      = "remove_x-powered-by_header"
    }, {
    enabled = false
    id      = "add_security_headers"
  }]
}

# ──────────────────────────────────────────────
# Email Routing
# ──────────────────────────────────────────────

resource "cloudflare_email_routing_catch_all" "zone" {
  enabled = false
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
  account_id                                  = var.cloudflare_account_id
  allow_authenticate_via_warp                 = false
  auth_domain                                 = "edenkeystone.cloudflareaccess.com"
  is_ui_read_only                             = false
  name                                        = "edenkeystone.cloudflareaccess.com"
  login_design                                = {}
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

resource "cloudflare_zero_trust_gateway_settings" "account" {
  account_id = var.cloudflare_account_id
  settings = {
    activity_log = null
    antivirus    = null
    block_page   = null
    certificate = {
      binding_status = "pending_deployment"
      id             = "6ab46d2a-4ce3-4607-a989-09f17c0acb22"
      qs_pack_id     = "9509fae9-3e6e-488a-9e16-1a059e9a348c"
      updated_at     = "0001-01-01T00:00:00Z"
    }
    fips = null
    tls_decrypt = {
      enabled = false
    }
  }
}

# ──────────────────────────────────────────────
# Zero Trust Gateway — Policies
# ──────────────────────────────────────────────

resource "cloudflare_zero_trust_gateway_policy" "do_not_inspect" {
  account_id    = var.cloudflare_account_id
  action        = "off"
  description   = "This policy excludes from inspection applications which are known to have desktop apps with certificate pinning, and other similar conditions which cannot support inspection. There may be applications in this list which you choose to remove over time."
  enabled       = true
  filters       = ["http"]
  name          = "Do Not Inspect"
  precedence    = 0
  traffic       = "any(app.type.ids[*] in {16})"
  rule_settings = {}
}

resource "cloudflare_zero_trust_gateway_policy" "default_deny_private" {
  account_id  = var.cloudflare_account_id
  action      = "block"
  description = "A catch-all policy to block all private traffic destined for the RFC1918 address space. This is meant to be your lowest-precedence network policy, which enables you to build allow policies and Access Applications to grant users access to applications and services on your private network. It also includes the default assignment range for Cloudflare One client devices in the CGNat space."
  enabled     = false
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
