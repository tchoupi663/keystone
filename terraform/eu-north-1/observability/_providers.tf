// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

provider "aws" {
  region = "eu-north-1"
}
provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}
