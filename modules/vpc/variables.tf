
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

variable "connectivity_type" {
  description = "Connectivity type for the NAT gateway"
  type        = string
  default     = "public"
}

variable "enable_internet_gateway" {
  description = "Enable internet gateway"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone."
  type        = bool
  default     = false
}
