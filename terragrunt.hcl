locals {
  # Parse the stack path: terraform/<region>/<layer>/envs/<env>
  path_parts = split("/", path_relative_to_include())
  region     = local.path_parts[1]
  layer      = local.path_parts[2]
  env        = local.path_parts[4]
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "keystone-tfstate-${local.env}"
    key            = "${local.layer}/${local.env}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock-${local.env}"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "${local.env}"
      Layer       = "${local.layer}"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}
