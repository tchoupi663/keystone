// TERRAMATE GENERATED FILE - DO NOT EDIT

terraform_binary = "terraform"

locals {
  workspace = basename(get_terragrunt_dir())
  app_name  = basename(get_parent_terragrunt_dir())
}

terraform {
  source = "${get_repo_root()}/terraform//eu-north-1/${local.app_name}"

  extra_arguments "disable_input" {
    commands  = get_terraform_commands_that_need_input()
    arguments = ["-input=false"]
  }

  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=5m"]
  }
}

generate "tfvars" {
  path              = "terragrunt.auto.tfvars.json"
  if_exists         = "overwrite_terragrunt"
  disable_signature = true
  contents          = jsonencode(merge(
    jsondecode(read_tfvars_file(find_in_parent_folders("tfvars/${local.workspace}.tfvars"))),
    {
      component = local.app_name
    }
  ))
}
