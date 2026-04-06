environment = "prod"

tunnel_origin_port = 8080

# Cloudflare Customization
# These values are currently set to their defaults in the module.
# You can uncomment and modify them here for environment-specific configuration.

# tiered_cache = "off"
# email_routing_catch_all_enabled = false

# waf_rate_limit_rules = [
#   {
#     action      = "block"
#     description = "Leaked credential check"
#     enabled     = true
#     expression  = "(cf.waf.credential_check.password_leaked)"
#     name        = "Leaked Credential Check"
#     ratelimit = {
#       characteristics     = ["ip.src", "cf.colo.id"]
#       mitigation_timeout  = 10
#       period              = 10
#       requests_per_period = 5
#     }
#   }
# ]

# waf_custom_rules = [
#   {
#     action      = "block"
#     description = "Block /health endpoint"
#     enabled     = true
#     expression  = "(http.request.uri.path eq \"/health\")"
#     name        = "Block Health Endpoint"
#   },
#   {
#     action      = "block"
#     description = "Block common probes and scanners"
#     enabled     = true
#     expression  = "(http.request.uri.path contains \"/.env\") or (http.request.uri.path contains \"/.git\") or (http.request.uri.path contains \"/wp-\") or (http.request.uri.path contains \"/admin\") or (http.request.uri.path contains \"/config\") or (http.request.uri.path contains \"/setup\") or (http.request.uri.path contains \".php\") or (http.request.uri.path contains \"/login\")"
#     name        = "Block Probes and Scanners"
#   }
# ]

# zero_trust_gateway_policy = [
#   {
#     action      = "off"
#     description = "This policy excludes from inspection applications which are known to have desktop apps with certificate pinning."
#     enabled       = true
#     filters       = ["http"]
#     name          = "Do Not Inspect"
#     precedence    = 0
#     traffic       = "any(app.type.ids[*] in {16})"
#   },
#   {
#     action      = "block"
#     description = "A catch-all policy to block all private traffic destined for the RFC1918 address space."
#     enabled     = true
#     filters     = ["l4"]
#     name          = "Default deny for private traffic"
#     precedence  = 10000
#     traffic     = "net.dst.ip in {10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.96.0.0/12}"
#     rule_settings = {
#       notification_settings = {
#         enabled = true
#         msg     = "This connection has been blocked by your account default-deny network policy."
#       }
#     }
#   }
# ]