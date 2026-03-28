terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "keystone-apps-terraform-state"
    region       = "eu-north-1"
    key          = "apps/eu-north-1/apps.tfstate"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}
