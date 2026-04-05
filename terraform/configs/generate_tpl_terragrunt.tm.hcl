generate_file "_tpl_terragrunt.hcl" {
  condition = tm_contains(terramate.stack.tags, "parent")
  content   = <<-EOF
    // TERRAMATE GENERATED FILE - DO NOT EDIT

    terraform_binary = "terraform"

    locals {
      workspace = basename(get_terragrunt_dir())
      app_name  = basename(get_parent_terragrunt_dir())
    }

    terraform {
      source = "$${get_repo_root()}/terraform//eu-north-1/$${local.app_name}"

      extra_arguments "disable_input" {
        commands  = get_terraform_commands_that_need_input()
        arguments = ["-input=false"]
      }

      extra_arguments "retry_lock" {
        commands  = get_terraform_commands_that_need_locking()
        arguments = ["-lock-timeout=5m"]
      }
    }

    inputs = merge(
      jsondecode(read_tfvars_file(find_in_parent_folders("tfvars/$${local.workspace}.tfvars"))),
      {
        component = local.app_name
      }
    )
    EOF
}