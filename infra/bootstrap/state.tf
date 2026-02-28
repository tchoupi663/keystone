terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "dev/bootstrap/eu-north-1/bootstrap.tfstate"
    use_lockfile = true
  }
}
