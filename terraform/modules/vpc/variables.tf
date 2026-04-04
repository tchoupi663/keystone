# Naming and tagging

variable "tags" {
  description = "Additional tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

variable "project" {
  description = "Project name for tagging and resource identification"
  type        = string
  default     = "keystone"
}

variable "region" {
  description = "Define the region"
  type        = string
}

variable "environment" {
  description = "Environment name (used in resource naming and tagging)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "preprod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, preprod"
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid CIDR notation (e.g., 10.0.0.0/16)"
  }
}

variable "public_subnets_count" {
  description = "Number of public subnets"
  type        = number
  default     = 1
  validation {
    condition     = var.public_subnets_count >= 0 && var.public_subnets_count <= 4
    error_message = "public_subnets_count must be between 0 and 4"
  }
}

variable "private_subnets_count" {
  description = "Number of private subnets"
  type        = number
  default     = 1
  validation {
    condition     = var.private_subnets_count >= 0 && var.private_subnets_count <= 4
    error_message = "private_subnets_count must be between 0 and 4"
  }
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

variable "nat_type" {
  description = "Type of NAT to use: 'gateway' for AWS NAT Gateway (~$32/mo), 'instance' for fck-nat EC2 (~$3/mo)"
  type        = string
  default     = "gateway"
  validation {
    condition     = contains(["gateway", "instance"], var.nat_type)
    error_message = "nat_type must be 'gateway' or 'instance'"
  }
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

variable "ha_mode" {
  description = "Enable high-availability mode for EC2 NAT gateway"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "EC2 instance type for NAT gateway"
  type        = string
  default     = "t4g.nano"
}

variable "use_cloudwatch_agent" {
  description = "Enable CloudWatch agent for NAT gateway"
  type        = bool
  default     = true
}

variable "update_route_tables" {
  description = "Update route tables for NAT gateway"
  type        = bool
  default     = true
}

variable "database_subnets_count" {
  description = "Number of isolated database subnets (no internet route). Should match AZ count for RDS Multi-AZ"
  type        = number
  default     = 0
}

variable "create_database_subnet_group" {
  description = "Create an RDS DB Subnet Group from the database subnets"
  type        = bool
  default     = true
}

variable "enable_custom_nacls" {
  description = "Deploy custom Network ACLs for public and private subnets with explicit allow rules"
  type        = bool
  default     = false
}

variable "enable_s3_endpoint" {
  description = "Provision a free S3 Gateway Endpoint to avoid NAT charges for S3 traffic"
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "Set of AWS service names to create Interface VPC Endpoints for (e.g., ecr.api, ecr.dkr, sts, logs, monitoring)"
  type        = set(string)
  default     = []
  # Example for EKS: ["ecr.api", "ecr.dkr", "sts", "logs", "elasticloadbalancing"]
  # Example for ECS: ["ecr.api", "ecr.dkr", "ecs", "ecs-agent", "ecs-telemetry", "logs"]
}

