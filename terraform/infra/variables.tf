variable "region" {
  description = "Define the region"
  type        = string
}

variable "environment" {
  description = "Define the environment"
  type        = string
}

variable "project" {
  description = "Define the project"
  type        = string
}

variable "cidr_block" {
  description = "Define IP address range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "listener_rules" {
  description = "Map of host-based listener rules for the ALB. Each rule forwards traffic to the default target group when the Host header matches."
  type = map(object({
    priority     = number
    host_headers = list(string)
  }))
  default = {}
}
