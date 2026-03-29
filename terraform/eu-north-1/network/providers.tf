terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    key          = "network/eu-north-1/network.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
}

provider "aws" {
  region = var.region
}