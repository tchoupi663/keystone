output "dns_records_subdomains" {
  description = "The DNS record names for subdomains"
  value       = [for r in cloudflare_dns_record.subdomain_cnames : r.name]
}

output "dns_record_root" {
  description = "The DNS record name for the root domain"
  value       = cloudflare_dns_record.root.name
}
