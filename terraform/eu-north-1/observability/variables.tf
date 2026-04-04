# Variables for observability stack
# grafana_url and grafana_auth are now fetched from SSM/Secrets Manager

variable "grafana_folder_title" {
  description = "Custom title for the Grafana folder. If not provided, a default title based on project and environment will be used."
  type        = string
  default     = null
}

variable "dashboards" {
  description = "Map of dashboards to create. The key is used as the dashboard identifier."
  type = map(object({
    file      = string
    overwrite = optional(bool, true)
  }))
  default = {
    app = {
      file = "app_dashboard.json"
    }
    infra = {
      file = "infra_dashboard.json"
    }
  }
}
