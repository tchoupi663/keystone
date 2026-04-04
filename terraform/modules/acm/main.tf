# ──────────────────────────────────────────────
# ACM Certificate — DNS-validated
# ──────────────────────────────────────────────

resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = ["demo.${var.domain_name}"]
  validation_method         = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alb-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Wait for the certificate to be validated before proceeding
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = var.validation_record_fqdns
}
