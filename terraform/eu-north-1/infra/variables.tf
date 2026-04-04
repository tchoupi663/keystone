
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

# --- VPC Configuration ---

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Specify if instances should receive a public IP"
  type        = bool
  default     = true
}

variable "connectivity_type" {
  description = "Infrastructure connectivity type (public/private)"
  type        = string
  default     = "public"
}

variable "enable_internet_gateway" {
  description = "Provision an Internet Gateway for the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Provision a NAT Gateway for the private subnets"
  type        = bool
  default     = true
}

variable "nat_type" {
  description = "Type of NAT to use (gateway/instance)"
  type        = string
  default     = "instance"
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Use one NAT Gateway per availability zone"
  type        = bool
  default     = false
}

variable "create_database_subnet_group" {
  description = "Create a database subnet group for RDS"
  type        = bool
  default     = true
}

variable "enable_custom_nacls" {
  description = "Enable custom Network ACLs"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable VPC Endpoint for S3"
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "List of services for which to create interface endpoints"
  type        = list(string)
  default     = []
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# --- ECS Configuration ---

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

# --- ALB Configuration ---

variable "alb_internal" {
  description = "If true, the ALB will be internal"
  type        = bool
  default     = false
}

variable "alb_enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "alb_drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with invalid header fields are removed by the load balancer"
  type        = bool
  default     = true
}

variable "alb_enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in the load balancer"
  type        = bool
  default     = true
}

variable "alb_ssl_policy" {
  description = "The name of the SSL Policy for the listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-1-2021-06"
}

variable "alb_target_group_port" {
  description = "The port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "alb_target_group_protocol" {
  description = "The protocol to use for routing traffic to the targets"
  type        = string
  default     = "HTTP"
}

variable "alb_target_type" {
  description = "The type of target that you must specify when registering targets with this target group"
  type        = string
  default     = "ip"
}

variable "alb_deregistration_delay" {
  description = "The amount of time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused"
  type        = number
  default     = 30
}

variable "alb_health_check" {
  description = "Health check configuration block"
  type        = any
  default     = {}
}

variable "alb_enable_access_logs" {
  description = "If true, access logs will be enabled"
  type        = bool
  default     = true
}

variable "alb_access_logs_bucket" {
  description = "The S3 bucket name to store the logs in"
  type        = string
  default     = ""
}

variable "alb_access_logs_prefix" {
  description = "The S3 bucket prefix"
  type        = string
  default     = "alb-logs"
}

variable "alb_ingress_cidr_blocks" {
  description = "List of CIDR blocks to allow ingress traffic on the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- ACM Configuration ---

variable "acm_validation_record_fqdns" {
  description = "List of FQDNs for DNS validation records"
  type        = list(string)
  default     = []
}

# --- Common Tags ---

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
