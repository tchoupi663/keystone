region      = "eu-north-1"
environment = "prod"
project     = "keystone"

# For production, restore from a snapshot for data continuity
# snapshot_identifier = "keystone-prod-db-manual-snap"

# Production Safety Settings - EXPLICITLY CONFIGURED
# These MUST be set correctly to prevent data loss
skip_final_snapshot = false  # CRITICAL: Always take final snapshot before deletion
deletion_protection = true   # CRITICAL: Prevent accidental terraform destroy
multi_az            = true   # High availability across availability zones

# Disaster Recovery - Cross-Region Backup
enable_cross_region_backup = true       # Replicate backups to DR region
backup_replication_region  = "eu-west-1" # DR region (Ireland)

# Note: Production RDS automatically configured with:
# - No scheduled scaling (runs 24/7)
# Consider also enabling:
# - Enhanced monitoring (in main.tf)
# - Performance Insights (in main.tf)
# - Larger instance class if needed (db.t4g.small or larger)

