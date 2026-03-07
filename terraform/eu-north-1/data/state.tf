terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "data/eu-north-1/data.tfstate"
    use_lockfile = true
  }
}