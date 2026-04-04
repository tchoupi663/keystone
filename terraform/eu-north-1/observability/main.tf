resource "grafana_folder" "keystone" {
  title = var.grafana_folder_title != null ? var.grafana_folder_title : "${title(var.project)} - ${title(var.environment)}"
}

resource "grafana_dashboard" "dashboards" {
  for_each = var.dashboards

  folder      = grafana_folder.keystone.id
  config_json = file("${path.module}/dashboards/${each.value.file}")
  overwrite   = each.value.overwrite
}
