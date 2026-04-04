output "tunnel_id" {
  description = "The ID of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_name" {
  description = "The name of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "tunnel_token_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret containing the tunnel token"
  value       = aws_secretsmanager_secret.tunnel_token.arn
}

output "tunnel_cname" {
  description = "The CNAME target for the Cloudflare Tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}
