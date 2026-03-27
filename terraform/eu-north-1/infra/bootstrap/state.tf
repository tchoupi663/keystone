terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "bootstrap/eu-north-1/bootstrap.tfstate"
    use_lockfile = true
  }
}
