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
      version = "~> 5.70"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.5"
    }
  }
}