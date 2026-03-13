terramate {
  config {
    git {
      default_branch         = "main"
      default_remote         = "origin"
      check_untracked        = true
      check_uncommitted      = true
      check_remote           = true
    }
  }
}

globals "project" {
  name   = "keystone"
  region = "eu-north-1"
}

# Code-generation: render terragrunt.hcl into every stack
generate_hcl "terragrunt.hcl" {
  condition = true

  content {
    terraform {
      source = global.stack.terraform_source

      before_hook "init_check" {
        commands = ["init"]
        execute  = ["echo", "==> Initialising stack: ${global.stack.stack_path}"]
      }
      after_hook "init_success" {
        commands     = ["init"]
        execute      = ["echo", "==> Init complete"]
        run_on_error = false
      }
      before_hook "plan_check" {
        commands = ["plan"]
        execute  = ["echo", "==> Planning stack: ${global.stack.stack_path} (env: ${global.stack.env})"]
      }
      after_hook "plan_output" {
        commands     = ["plan"]
        execute      = ["sh", "-c", "echo '==> Plan finished. Review before applying.'"]
        run_on_error = true
      }
      before_hook "apply_guard" {
        commands = ["apply"]
        execute  = ["echo", "==> Applying stack: ${global.stack.stack_path}"]
      }
      after_hook "apply_notify" {
        commands     = ["apply"]
        execute      = ["echo", "==> Apply complete for ${global.stack.stack_path}"]
        run_on_error = false
      }
      before_hook "destroy_guard" {
        commands = ["destroy"]
        execute  = ["echo", "WARNING: Destroying ${global.stack.stack_path} in ${global.stack.env}"]
      }
    }

    include "root" {
      path   = find_in_parent_folders("terragrunt.hcl")
      expose = true
    }

    terraform_binary = global.stack.terraform_binary
    inputs           = global.stack.inputs
  }
}
