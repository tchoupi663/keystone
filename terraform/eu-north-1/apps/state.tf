terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "apps/eu-north-1/apps.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
