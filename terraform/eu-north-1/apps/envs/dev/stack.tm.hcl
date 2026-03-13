stack {
  name        = "eu-north-1-apps-dev"
  description = "Apps layer - dev environment"
  tags        = ["apps", "dev", "eu-north-1", "aws"]

  after = ["/terraform/eu-north-1/infra/envs/dev", "/terraform/eu-north-1/data/envs/dev"]
}

globals "stack" {
  env              = "dev"
  stack_path       = terramate.stack.path
  terraform_source = global.layer.terraform_source
  terraform_binary = "terraform"

  inputs = {
    region                          = "eu-north-1"
    environment                     = "dev"
    project                         = "keystone"
    capacity_provider_strategy      = [
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
    app_image_repository            = "ghcr.io/tchoupi663/keystone"
    image_tag                       = "app-1.0.0"
  }
}
