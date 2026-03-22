variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name to serve via CloudFront"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB Origin DNS Name"
  type        = string
}

variable "acm_certificate_arn" {
  description = "Global ACM Certificate ARN (us-east-1)"
  type        = string
}
