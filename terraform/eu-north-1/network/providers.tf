terraform {
  backend "s3" {
    bucket = "keystone-infra-terraform-state"
    key    = "network/eu-north-1/network.tfstate"
    region = "eu-north-1"
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