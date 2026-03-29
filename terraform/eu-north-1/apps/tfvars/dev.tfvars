
region      = "eu-north-1"
environment = "dev"
project     = "keystone"

capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  },
  {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
    base              = 0
  }
]

github_token_secret_name = "keystone/dev/github-token"
grafana_loki_user        = "1511095"

grafana_prometheus_url  = "https://prometheus-prod-55-prod-gb-south-1.grafana.net/api/prom/push"
grafana_prometheus_user = "3030840"

app_image_repository = "ghcr.io/tchoupi663/keystone"
image_tag            = "app-1.0.31"

grafana_tempo_endpoint = "tempo-prod-25-prod-gb-south-1.grafana.net:443"
grafana_tempo_user     = "1505400"
