// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "project" {
  default     = "keystone"
  description = "Project name"
  type        = string
}
variable "region" {
  default     = "eu-north-1"
  description = "AWS region"
  type        = string
}
variable "environment" {
  description = "Deployment environment"
  type        = string
}
variable "top_domain_name" {
  default     = "edenkeystone.com"
  description = "Top Domain name"
  type        = string
}
variable "subdomains" {
  default = [
    "demo",
    "www",
  ]
  description = "List of subdomains"
  type        = list(string)
}
variable "terraform_state_bucket" {
  default     = "keystone-infra-terraform-state"
  description = "Terraform remote state bucket name"
  type        = string
}
