// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    encrypt      = true
    key          = "infra/eu-north-1/infra.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}
