variable "domain_name" {
  description = "The domain name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}

variable "domain_validation_options" {
  description = "ACM domain validation options"
  type        = any
}
