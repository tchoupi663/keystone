
variable "region" {
  description = "Define the region"
  type        = string
}

variable "environment" {
  description = "Define the environment"
  type        = string
}

variable "cidr_block" {
  description = "Define IP address range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Enable public IP on launch"
  type        = bool
  default     = true
}

variable "public_subnets_count" {
  description = "Number of public subnets in the VPC"
  type        = number
  default     = 1
}

variable "private_subnets_count" {
  description = "Number of private subnets in the VPC"
  type        = number
  default     = 1
}

