
region      = "eu-north-1"
environment = "staging"
project     = "keystone"

# Capacity Provider Strategy for Staging Environment
# - Staging uses a balanced approach for cost vs reliability
# - FARGATE with base = 1 ensures stable baseline capacity
# - FARGATE_SPOT with weight = 2 handles scale-out for cost savings
# - Always maintains at least one reliable FARGATE task
capacity_provider_strategy = [
  {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 1
  },
  {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
  }
]

# Secrets Manager References
github_token_secret_name = "keystone/staging/github-token"

# Grafana Cloud Configuration
grafana_loki_user = "1511095"  # Update with staging-specific user if different

grafana_prometheus_url  = "https://prometheus-prod-55-prod-gb-south-1.grafana.net/api/prom/push"
grafana_prometheus_user = "3030840"  # Update with staging-specific user if different

# Container Image
app_image_repository = "ghcr.io/tchoupi663/keystone"
image_tag            = "app-1.0.25"  # Update to staging releases

# Grafana Tempo (Tracing)
grafana_tempo_endpoint = "tempo-prod-25-prod-gb-south-1.grafana.net:443"
grafana_tempo_user     = "1505400"  # Update with staging-specific user if different

# NOTE: Before using this file:
# 1. Create the GitHub token secret: keystone/staging/github-token
# 2. Update image_tag to a tested staging release
# 3. Review and update Grafana Cloud user IDs if using separate workspaces
# 4. Verify network and data layer outputs are available
