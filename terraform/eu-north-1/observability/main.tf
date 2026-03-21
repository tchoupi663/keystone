terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "keystone-infra-terraform-state"
    key     = "observability/eu-north-1/observability.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.0.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    }
  }
}

data "aws_secretsmanager_secret" "grafana_workspace_token" {
  name = var.grafana_workspace_token_secret_name
}

data "aws_secretsmanager_secret_version" "grafana_workspace_token" {
  secret_id = data.aws_secretsmanager_secret.grafana_workspace_token.id
}

provider "grafana" {
  url  = var.grafana_url
  auth = jsondecode(data.aws_secretsmanager_secret_version.grafana_workspace_token.secret_string)["grafana-workspace-token"]
}

resource "grafana_folder" "keystone" {
  title = "Keystone ${title(var.environment)}"
}

resource "grafana_dashboard" "app_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/app_dashboard.json")
  overwrite   = true
}

resource "grafana_dashboard" "infra_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/infra_dashboard.json")
  overwrite   = true
}
