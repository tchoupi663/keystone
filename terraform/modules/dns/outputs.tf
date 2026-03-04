output "zone_id" {
  description = "The Route53 Zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "validation_record_fqdns" {
  description = "FQDNs of the validation records built"
  value       = [for record in aws_route53_record.cert_validation : record.fqdn]
}
