locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────────
# Cloudflare Infrastructure
# ──────────────────────────────────────────────

module "cloudflare" {
  source = "../../modules/cloudflare"

  project               = var.project
  environment           = var.environment
  cloudflare_zone_id     = var.cloudflare_zone_id
  cloudflare_account_id  = var.cloudflare_account_id
}

