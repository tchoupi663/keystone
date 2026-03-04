variable "domain_name" {
  description = "The domain name for the certificate"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, preprod)"
  type        = string
}

variable "project" {
  description = "Project name for tagging and resource identification"
  type        = string
  default     = "keystone"
}

variable "validation_record_fqdns" {
  description = "List of FQDNs for DNS validation records"
  type        = list(string)
  default     = []
}
