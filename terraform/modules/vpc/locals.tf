# ──────────────────────────────────────────────
# Tagging
# ──────────────────────────────────────────────

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Region      = var.region
      Project     = var.project
      ManagedBy   = "terraform"
      Module      = "vpc"
    },
    var.tags
  )
}

# ──────────────────────────────────────────────
# NAT & Routing
# ──────────────────────────────────────────────

locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? var.public_subnets_count : 1)) : 0

  use_nat_gateway  = var.enable_nat_gateway && var.nat_type == "gateway"
  use_nat_instance = var.enable_nat_gateway && var.nat_type == "instance"

  nat_gw_count       = local.use_nat_gateway ? local.nat_gateway_count : 0
  nat_instance_count = local.use_nat_instance ? local.nat_gateway_count : 0

  private_route_table_ids = { for i, rt in aws_route_table.private : "private-${i}" => rt.id }
}
