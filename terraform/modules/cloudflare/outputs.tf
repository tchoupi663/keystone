output "tunnel_id" {
  description = "ID of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_name" {
  description = "Name of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "tunnel_cname" {
  description = "CNAME target for the tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}

output "tunnel_token_secret_arn" {
  description = "ARN of the AWS Secret containing the Cloudflare Tunnel token"
  value       = aws_secretsmanager_secret.tunnel_token.arn
}
