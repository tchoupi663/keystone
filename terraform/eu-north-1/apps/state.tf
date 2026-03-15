terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "apps/eu-north-1/apps.tfstate"
    use_lockfile = true
  }
}
