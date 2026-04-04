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

module "cloudflare_tunnel" {
  source = "../../modules/cloudflare-tunnel"

  project               = var.project
  environment           = var.environment
  cloudflare_account_id = data.aws_ssm_parameter.cloudflare_account_id.value
  region                = var.region
  domain_name           = var.top_domain_name
  subdomains            = var.subdomains
  tunnel_origin_port    = var.tunnel_origin_port

  tags = var.tags
}

module "cloudflare_security" {
  source = "../../modules/cloudflare-security"

  project               = var.project
  environment           = var.environment
  cloudflare_zone_id    = data.aws_ssm_parameter.cloudflare_zone_id.value
  cloudflare_account_id = data.aws_ssm_parameter.cloudflare_account_id.value
  region                = var.region
  domain_name           = var.top_domain_name
  subdomains            = var.subdomains

  waf_rate_limit_rules      = var.waf_rate_limit_rules
  waf_custom_rules          = var.waf_custom_rules
  zero_trust_gateway_policy = var.zero_trust_gateway_policy

  tags = var.tags
}

module "cloudflare_dns" {
  source = "../../modules/cloudflare-dns"

  project            = var.project
  environment        = var.environment
  cloudflare_zone_id = data.aws_ssm_parameter.cloudflare_zone_id.value
  region             = var.region
  domain_name        = var.top_domain_name
  subdomains         = var.subdomains

  tunnel_id = module.cloudflare_tunnel.tunnel_id

  managed_transforms              = var.managed_transforms
  tiered_cache                    = var.tiered_cache
  email_routing_catch_all_enabled = var.email_routing_catch_all_enabled

  tags = var.tags
}

