// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    encrypt      = true
    key          = "apps/eu-north-1/apps.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}
