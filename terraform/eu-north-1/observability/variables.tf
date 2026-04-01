
variable "grafana_url" {
  description = "The Grafana Cloud Workspace URL"
  type        = string
}

variable "grafana_auth" {
  description = "The Grafana Cloud Service Account Token"
  type        = string
  sensitive   = true
}
