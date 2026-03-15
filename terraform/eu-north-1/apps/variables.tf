variable "region" {
  description = "Define the region"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Define the environment"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Define the project"
  type        = string
  default     = "keystone"
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for the ECS service. Mutually exclusive with launch_type."
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
  ]
}

variable "image_tag" {
  description = "Tag of the image to deploy"
  type        = string
}

variable "app_image_repository" {
  description = "Docker image repository URI on GitHub Packages"
  type        = string
}

variable "github_token_secret_name" {
  description = "Name of the AWS Secrets Manager secret storing the GitHub Packages access token (JSON with username and password keys)"
  type        = string
}

variable "grafana_loki_user" {
  description = "Grafana Cloud Loki numeric user ID (shown as 'User' in the Loki connection details page)."
  type        = string
}
