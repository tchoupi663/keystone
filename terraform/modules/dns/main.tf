data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ──────────────────────────────────────────────
# Certification Validation Records
# ──────────────────────────────────────────────
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in var.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ──────────────────────────────────────────────
# ALB Routing Records
# ──────────────────────────────────────────────

# Demo: demo.edenkeystone.com → ALB/CloudFront
resource "aws_route53_record" "demo" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "demo.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}
