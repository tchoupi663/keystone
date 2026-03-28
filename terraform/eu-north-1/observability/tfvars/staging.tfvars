region      = "eu-north-1"
environment = "staging"
project     = "keystone"

grafana_url = "https://edenkeystone.grafana.net"

# Replace with the name of the Secret you create in AWS Secrets Manager
grafana_workspace_token_secret_name = "grafana-dashboards"

# Grafana Loki datasource UID (found in Grafana → Connections → Data Sources → Loki → UID)
grafana_loki_datasource_uid = "grafanacloud-logs"
