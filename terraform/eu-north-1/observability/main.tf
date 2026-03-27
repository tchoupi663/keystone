
data "aws_secretsmanager_secret" "grafana_workspace_token" {
  name = var.grafana_workspace_token_secret_name
}

data "aws_secretsmanager_secret_version" "grafana_workspace_token" {
  secret_id = data.aws_secretsmanager_secret.grafana_workspace_token.id
}

provider "grafana" {
  url  = var.grafana_url
  auth = jsondecode(data.aws_secretsmanager_secret_version.grafana_workspace_token.secret_string)["grafana-workspace-token"]
}

resource "grafana_folder" "keystone" {
  title = "Keystone ${title(var.environment)}"
}

resource "grafana_dashboard" "app_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/app_dashboard.json")
  overwrite   = true
}

resource "grafana_dashboard" "infra_dashboard" {
  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/infra_dashboard.json")
  overwrite   = true
}
