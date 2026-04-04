# Cloudfront resources

resource "aws_s3_bucket" "error_pages" {
  bucket_prefix = "${var.project}-${var.environment}-error-pages-"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "error_pages" {
  bucket = aws_s3_bucket.error_pages.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "error_pages" {
  bucket                  = aws_s3_bucket.error_pages.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project}-${var.environment}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.error_pages.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "error_pages" {
  bucket = aws_s3_bucket.error_pages.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_object" "sleep_page" {
  bucket       = aws_s3_bucket.error_pages.id
  key          = "503_sleeping.html"
  source       = "${path.module}/503_sleeping.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/503_sleeping.html")
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project} ${var.environment} CDN"
  price_class     = "PriceClass_100"
  aliases         = ["demo.${var.domain_name}", var.domain_name]

  # Primary Origin: ALB
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Fallback Origin: S3 Error Pages
  origin {
    domain_name              = aws_s3_bucket.error_pages.bucket_regional_domain_name
    origin_id                = "S3-ErrorPages"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "ALB"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern           = "/503_sleeping.html"
    target_origin_id       = "S3-ErrorPages"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  custom_error_response {
    error_code            = 503
    response_code         = 503
    response_page_path    = "/503_sleeping.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 502
    response_code         = 503
    response_page_path    = "/503_sleeping.html"
    error_caching_min_ttl = 0
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.common_tags
}
