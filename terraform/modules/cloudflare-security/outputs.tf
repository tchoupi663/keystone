output "access_identity_provider_id" {
  description = "The ID of the Zero Trust Access Identity Provider"
  value       = cloudflare_zero_trust_access_identity_provider.otp.id
}

output "zero_trust_organization_id" {
  description = "The ID of the Zero Trust Organization"
  value       = cloudflare_zero_trust_organization.account.name
}
