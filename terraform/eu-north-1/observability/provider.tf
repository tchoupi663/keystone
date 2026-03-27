# ──────────────────────────────────────────────
# AWS Provider Configuration
# ──────────────────────────────────────────────
# Provider-level default_tags automatically apply
# to all resources created in this module.
# Resource-specific tags will merge with and
# override these defaults.
# ──────────────────────────────────────────────

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Layer       = "observability"
    }
  }
}
