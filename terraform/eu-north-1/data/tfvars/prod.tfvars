region      = "eu-north-1"
environment = "prod"
project     = "keystone"

# For production, restore from a snapshot for data continuity
# snapshot_identifier = "keystone-prod-db-manual-snap"

# Note: Production RDS automatically configured with:
# - Multi-AZ deployment (high availability)
# - Deletion protection enabled
# - Final snapshot on deletion
# - No scheduled scaling (runs 24/7)
# Consider also enabling:
# - Enhanced monitoring (in main.tf)
# - Performance Insights (in main.tf)
# - Larger instance class if needed (db.t4g.small or larger)

