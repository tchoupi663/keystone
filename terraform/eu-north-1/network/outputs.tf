output "tunnel_id" {
  description = "ID of the dev Cloudflare Tunnel"
  value       = module.cloudflare.tunnel_id
}

output "tunnel_cname" {
  description = "CNAME target for the tunnel used by DNS records"
  value       = module.cloudflare.tunnel_cname
}

output "zone_id" {
  description = "Cloudflare Zone ID (passthrough for downstream layers)"
  value       = var.cloudflare_zone_id
  sensitive   = true
}

output "account_id" {
  description = "Cloudflare Account ID (passthrough for downstream layers)"
  value       = var.cloudflare_account_id
  sensitive   = true
}

output "tunnel_token_secret_arn" {
  description = "ARN of the AWS Secret containing the Cloudflare Tunnel token"
  value       = module.cloudflare.tunnel_token_secret_arn
}
