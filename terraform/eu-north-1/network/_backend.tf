// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    encrypt      = true
    key          = "network/eu-north-1/network.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}
