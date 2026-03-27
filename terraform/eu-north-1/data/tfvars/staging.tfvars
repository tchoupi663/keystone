region      = "eu-north-1"
environment = "staging"
project     = "keystone"

# For staging, you can restore from a snapshot or start fresh
# snapshot_identifier = "keystone-staging-db-manual-snap"

# Note: Staging RDS automatically configured with:
# - Single-AZ deployment (cost optimization)
# - Deletion protection disabled
# - Skip final snapshot on deletion
# - Scheduled scaling enabled (stops overnight)

