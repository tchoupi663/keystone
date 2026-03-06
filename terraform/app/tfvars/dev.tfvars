
region      = "eu-north-1"
environment = "dev"
project     = "keystone"

capacity_provider_strategy = [
  {
    base           = 2
    capacity_provider = "FARGATE_SPOT"
  },
  {
    base           = 0
    capacity_provider = "FARGATE"
  }
]