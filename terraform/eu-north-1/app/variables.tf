variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
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

variable "github_token_ssm_parameter_name" {
  description = "Name of the SSM Parameter storing the GitHub Packages access token"
  type        = string
}
