region      = "eu-north-1"
environment = "staging"
project     = "keystone"

# For staging, you can restore from a snapshot or start fresh
# snapshot_identifier = "keystone-staging-db-manual-snap"

# Staging Safety Settings - Cost-optimized but with some protection
skip_final_snapshot = false  # Take snapshot for rollback capability
deletion_protection = false  # Allow deletion for environment cleanup
multi_az            = false  # Single-AZ for cost savings

# Disaster Recovery - Optional for staging
enable_cross_region_backup = false      # Can enable if staging needs DR testing
backup_replication_region  = "eu-west-1"

# Note: Staging RDS automatically configured with:
# - Scheduled scaling enabled (stops overnight)

