generate_file "_providers.tf" {
  condition = tm_contains(terramate.stack.tags, "parent")
  content   = <<-EOF
// TERRAMATE GENERATED FILE - DO NOT EDIT

%{ for p in global.providers ~}
%{ if p == "grafana" ~}

data "aws_ssm_parameter" "grafana_url" {
  name = "/$${var.project}/$${var.environment}/grafana/url"
}

data "aws_secretsmanager_secret_version" "grafana_token" {
  secret_id = "$${var.project}/$${var.environment}/grafana/token"
}

%{ endif ~}
provider "${p}" {
%{ if p == "aws" ~}
  region = "${global.region}"
%{ endif ~}
%{ if p == "grafana" ~}
  url  = data.aws_ssm_parameter.grafana_url.value
  auth = data.aws_secretsmanager_secret_version.grafana_token.secret_string
%{ endif ~}
}
%{ endfor ~}
EOF
}
