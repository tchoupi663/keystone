variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for edenkeystone.com"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}
