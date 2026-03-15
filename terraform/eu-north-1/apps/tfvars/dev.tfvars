
region      = "eu-north-1"
environment = "dev"
project     = "keystone"

capacity_provider_strategy = [
  {
    base              = 2
    capacity_provider = "FARGATE_SPOT"
  },
  {
    base              = 0
    capacity_provider = "FARGATE"
  }
]
github_token_secret_name = "keystone/dev/github-token"
grafana_loki_user = "1511095"

app_image_repository = "ghcr.io/tchoupi663/keystone"
image_tag            = "app-1.0.5"

