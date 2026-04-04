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

  tags = local.common_tags
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
