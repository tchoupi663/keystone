// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

data "aws_ssm_parameter" "grafana_loki_host" {
  name = "/${var.project}/${var.environment}/grafana/loki/host"
}
data "aws_ssm_parameter" "grafana_loki_user" {
  name = "/${var.project}/${var.environment}/grafana/loki/user"
}
data "aws_ssm_parameter" "grafana_prometheus_url" {
  name = "/${var.project}/${var.environment}/grafana/prometheus/url"
}
data "aws_ssm_parameter" "grafana_prometheus_user" {
  name = "/${var.project}/${var.environment}/grafana/prometheus/user"
}
data "aws_ssm_parameter" "grafana_tempo_endpoint" {
  name = "/${var.project}/${var.environment}/grafana/tempo/endpoint"
}
data "aws_ssm_parameter" "grafana_tempo_user" {
  name = "/${var.project}/${var.environment}/grafana/tempo/user"
}
data "aws_secretsmanager_secret" "grafana_loki_api_key" {
  name = "${var.project}/${var.environment}/grafana-loki-api-key"
}
data "aws_secretsmanager_secret_version" "grafana_loki_api_key" {
  secret_id = data.aws_secretsmanager_secret.grafana_loki_api_key.id
}
data "aws_secretsmanager_secret_version" "flow_logs_token" {
  secret_id = "${var.project}/${var.environment}/flow-logs-token"
}
