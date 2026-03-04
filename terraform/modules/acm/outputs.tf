output "certificate_arn" {
  description = "The ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "unvalidated_certificate_arn" {
  description = "The ARN of the unvalidated ACM certificate"
  value       = aws_acm_certificate.alb.arn
}

output "domain_validation_options" {
  description = "Domain validation options for Route53 records"
  value       = aws_acm_certificate.alb.domain_validation_options
}
