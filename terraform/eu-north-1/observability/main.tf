

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
