locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

data "aws_ssm_parameter" "cloudflare_account_id" {
  name = "/${var.project}/${var.environment}/cloudflare/account-id"
}

data "aws_ssm_parameter" "cloudflare_zone_id" {
  name = "/${var.project}/${var.environment}/cloudflare/zone-id"
}

module "cloudflare" {
  source = "../../modules/cloudflare"

  project               = var.project
  environment           = var.environment
  cloudflare_zone_id    = data.aws_ssm_parameter.cloudflare_zone_id.value
  cloudflare_account_id = data.aws_ssm_parameter.cloudflare_account_id.value
  domain_name           = var.top_domain_name
  subdomains            = var.subdomains

  waf_rate_limit_rules            = var.waf_rate_limit_rules
  waf_custom_rules                = var.waf_custom_rules
  managed_transforms              = var.managed_transforms
  zero_trust_gateway_policy       = var.zero_trust_gateway_policy
  tiered_cache                    = var.tiered_cache
  email_routing_catch_all_enabled = var.email_routing_catch_all_enabled
}

