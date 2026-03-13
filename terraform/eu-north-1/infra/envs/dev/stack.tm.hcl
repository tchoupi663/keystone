stack {
  name        = "eu-north-1-infra-dev"
  description = "Infrastructure layer - dev environment"
  tags        = ["infra", "dev", "eu-north-1", "aws"]

  after = []
}

globals "stack" {
  env              = "dev"
  stack_path       = terramate.stack.path
  terraform_source = global.layer.terraform_source
  terraform_binary = "terraform"

  inputs = {
    region                 = "eu-north-1"
    environment            = "dev"
    project                = "keystone"
    domain_name            = "edenkeystone.com"
    public_subnets_count   = 2
    private_subnets_count  = 2
    database_subnets_count = 2
    listener_rules         = {
      eden_keystone = {
        priority     = 100
        host_headers = ["demo.edenkeystone.com"]
      }
    }
  }
}
