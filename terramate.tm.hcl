import {
  source = "terraform/configs/*.tm.hcl"
}

terramate {
  config {
    disable_safeguards = [
      "git-uncommitted",
      "git-untracked"
    ]
    experiments = [
      "scripts"
    ]
  }
}

globals {
  region = "eu-north-1"
  project     = "keystone"

  aws_version        = "~> 6.0"
  grafana_version    = "~> 4.0"
  cloudflare_version = "~> 5.0"
  random_version     = "~> 3.0"

  app_image_repository = "ghcr.io/tchoupi663/keystone"

  domain_name = "edenkeystone.com"

  # List of providers to generate for the stack
  # Can be overridden in stack.tm.hcl
  providers = ["aws"]

  provider_configs = {
    aws = {
      source  = "hashicorp/aws"
      version = global.aws_version
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = global.cloudflare_version
    }
    grafana = {
      source  = "grafana/grafana"
      version = global.grafana_version
    }
    random = {
      source  = "hashicorp/random"
      version = global.random_version
    }
  }
}

generate_hcl "_common_variables.tf" {
  condition = tm_contains(terramate.stack.tags, "parent")
  content {

    variable "project" {
      type        = string
      description = "Project name"
      default     = global.project
    }

    variable "region" {
      type        = string
      description = "AWS region"
      default     = global.region
    }

    variable "environment" {
      type        = string
      description = "Deployment environment"
    }

    variable "top_domain_name" {
      type        = string
      description = "Top Domain name"
      default     = global.domain_name
    }
  }
}

script "init" {
  description = "init"
  job {
    name = "init"
    commands = [
      ["terragrunt", "init", "-reconfigure"]
    ]
  }
}

script "plan" {
  description = "plan"
  job {
    name = "plan"
    commands = [
      ["terragrunt", "plan"]
    ]
  }
}

script "apply" {
  description = "apply"
  job {
    name = "apply"
    commands = [
      ["terragrunt", "apply", "-auto-approve"]
    ]
  }
}

script "destroy" {
  description = "destroy"
  job {
    name = "destroy"
    commands = [
      ["terragrunt", "destroy", "-auto-approve"]
    ]
  }
}
