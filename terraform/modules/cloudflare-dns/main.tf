# ──────────────────────────────────────────────
# DNS Records
# ──────────────────────────────────────────────

resource "cloudflare_dns_record" "subdomain_cnames" {
  for_each = toset(var.subdomains)

  content = "${var.tunnel_id}.cfargotunnel.com"
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
  content = "${var.tunnel_id}.cfargotunnel.com"
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
