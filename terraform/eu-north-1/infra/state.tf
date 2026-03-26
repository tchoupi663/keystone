terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "infra/eu-north-1/infra.tfstate"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}
