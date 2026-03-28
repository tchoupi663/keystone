variable "region" {
  description = "Define the region"
  type        = string
  default     = "eu-north-1"
}

variable "grafana_loki_host" {
  description = "Grafana Cloud Loki host for Firehose (e.g. logs-prod-035.grafana.net)"
  type        = string
}

variable "grafana_loki_user" {
  description = "Grafana user ID"
  type        = string
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

variable "cidr_block" {
  description = "Define IP address range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "private_subnets_count" {
  description = "Number of private subnets"
  type        = number
  default     = 2
}

variable "database_subnets_count" {
  description = "Number of database subnets"
  type        = number
  default     = 2
}
