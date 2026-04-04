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
  project                = "keystone"
  terraform_state_bucket = "keystone-infra-terraform-state"

  aws_version        = "~> 6.0"
  cloudflare_version = "~> 5.0"
  grafana_version    = "~> 4.0"
  random_version     = "~> 3.0"

  app_image_repository = "ghcr.io/tchoupi663/keystone"

  domain_name = "edenkeystone.com"
  subdomains  = ["demo", "www"]

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

    variable "subdomains" {
      type        = list(string)
      description = "List of subdomains"
      default     = global.subdomains
    }

    variable "terraform_state_bucket" {
      type        = string
      description = "Terraform remote state bucket name"
      default     = global.terraform_state_bucket
    }
  }
}

generate_hcl "_shared_data.tf" {
  condition = tm_contains(terramate.stack.tags, "observability-data")
  content {
    # ── Grafana Loki (Logs)
    data "aws_ssm_parameter" "grafana_loki_host" {
      name = "/${var.project}/${var.environment}/grafana/loki/host"
    }

    data "aws_ssm_parameter" "grafana_loki_user" {
      name = "/${var.project}/${var.environment}/grafana/loki/user"
    }

    # ── Grafana Prometheus (Metrics)
    data "aws_ssm_parameter" "grafana_prometheus_url" {
      name = "/${var.project}/${var.environment}/grafana/prometheus/url"
    }

    data "aws_ssm_parameter" "grafana_prometheus_user" {
      name = "/${var.project}/${var.environment}/grafana/prometheus/user"
    }

    # ── Grafana Tempo (Traces)
    data "aws_ssm_parameter" "grafana_tempo_endpoint" {
      name = "/${var.project}/${var.environment}/grafana/tempo/endpoint"
    }

    data "aws_ssm_parameter" "grafana_tempo_user" {
      name = "/${var.project}/${var.environment}/grafana/tempo/user"
    }

    # ── Secrets
    data "aws_secretsmanager_secret" "grafana_loki_api_key" {
      name = "${var.project}/${var.environment}/grafana-loki-api-key"
    }

    data "aws_secretsmanager_secret_version" "grafana_loki_api_key" {
      secret_id = data.aws_secretsmanager_secret.grafana_loki_api_key.id
    }

    # Flow logs specific secret (backward compatibility/standardization)
    data "aws_secretsmanager_secret_version" "flow_logs_token" {
      secret_id = "${var.project}/${var.environment}/flow-logs-token"
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
