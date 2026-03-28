region      = "eu-north-1"
environment = "dev"
project     = "keystone"

snapshot_identifier = "keystone-dev-db-manual-snap"

# Development Safety Settings - Cost-optimized, can skip snapshots
skip_final_snapshot = true   # Dev can skip final snapshot for faster teardown
deletion_protection = false  # Allow deletion for rapid iteration
multi_az            = false  # Single-AZ for cost savings