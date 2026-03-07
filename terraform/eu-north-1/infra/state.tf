terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "infra/eu-north-1/infra.tfstate"
    use_lockfile = true
  }
}