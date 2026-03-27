
region      = "eu-north-1"
environment = "prod"
project     = "keystone"

# Capacity Provider Strategy for Production Environment
# - Production prioritizes reliability over cost
# - FARGATE with base = 2 ensures two tasks always run on reliable infrastructure
# - FARGATE_SPOT with weight = 1 handles scale-out only (never used for base capacity)
# - This configuration guarantees HA with automatic failover across AZs
capacity_provider_strategy = [
  {
    base              = 2
    capacity_provider = "FARGATE"
    weight            = 1
  },
  {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
]

# Secrets Manager References
github_token_secret_name = "keystone/prod/github-token"

# Grafana Cloud Configuration
grafana_loki_user = "1511095"  # Update with production-specific user

grafana_prometheus_url  = "https://prometheus-prod-55-prod-gb-south-1.grafana.net/api/prom/push"
grafana_prometheus_user = "3030840"  # Update with production-specific user

# Container Image
app_image_repository = "ghcr.io/tchoupi663/keystone"
image_tag            = "app-1.0.25"  # Use production-approved image tags

# Grafana Tempo (Tracing)
grafana_tempo_endpoint = "tempo-prod-25-prod-gb-south-1.grafana.net:443"
grafana_tempo_user     = "1505400"  # Update with production-specific user

# IMPORTANT: Production Pre-Deployment Checklist
# ------------------------------------------------
# 1. Create the GitHub token secret: keystone/prod/github-token
# 2. Set image_tag to a TESTED and APPROVED production release
# 3. Configure separate Grafana Cloud workspace for prod (recommended)
# 4. Enable RDS Multi-AZ in data layer (data/tfvars/prod.tfvars)
# 5. Increase desired_count to minimum 2 tasks
# 6. Review and adjust autoscaling thresholds
# 7. Disable scale-to-zero schedules
# 8. Configure CloudWatch alarms and SNS notifications
# 9. Test disaster recovery procedures
# 10. Document on-call runbooks
