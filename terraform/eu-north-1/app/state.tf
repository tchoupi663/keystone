terraform {
  backend "s3" {
    bucket       = "keystone-infra-terraform-state"
    region       = "eu-north-1"
    key          = "app/eu-north-1/app.tfstate"
    use_lockfile = true
  }
}