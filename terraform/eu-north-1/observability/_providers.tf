// TERRAMATE GENERATED FILE - DO NOT EDIT

provider "aws" {
  region = "eu-north-1"
}

data "aws_ssm_parameter" "grafana_url" {
  name = "/${var.project}/${var.environment}/grafana/url"
}

data "aws_secretsmanager_secret_version" "grafana_token" {
  secret_id = "${var.project}/${var.environment}/grafana/token"
}

provider "grafana" {
  url  = data.aws_ssm_parameter.grafana_url.value
  auth = data.aws_secretsmanager_secret_version.grafana_token.secret_string
}
