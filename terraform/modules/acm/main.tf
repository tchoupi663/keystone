# ──────────────────────────────────────────────
# ACM Certificate — DNS-validated
# ──────────────────────────────────────────────

resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name        = "${var.project}-${var.environment}-alb-cert"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Wait for the certificate to be validated before proceeding
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = var.validation_record_fqdns
}
