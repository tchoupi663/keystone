variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "keystone"
}

variable "grafana_url" {
  description = "The Grafana Cloud Workspace URL"
  type        = string
}

variable "grafana_workspace_token_secret_name" {
  description = "Name of the AWS Secret containing the Grafana Service Account Token"
  type        = string
}
