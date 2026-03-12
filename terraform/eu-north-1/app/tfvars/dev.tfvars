
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
github_token_ssm_parameter_name = "/keystone/dev/github_token"

app_image_repository = "ghcr.io/tchoupi663/keystone"
image_tag = "app-1.0.3"
