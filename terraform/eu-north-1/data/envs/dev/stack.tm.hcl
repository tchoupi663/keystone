stack {
  name        = "eu-north-1-data-dev"
  description = "Data layer - dev environment"
  tags        = ["data", "dev", "eu-north-1", "aws"]

  after = ["/terraform/eu-north-1/infra/envs/dev"]
}

globals "stack" {
  env              = "dev"
  stack_path       = terramate.stack.path
  terraform_source = global.layer.terraform_source
  terraform_binary = "terraform"

  inputs = {
    region      = "eu-north-1"
    environment = "dev"
    project     = "keystone"
  }
}
