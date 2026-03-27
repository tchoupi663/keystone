provider "aws" {
  region = "eu-north-1"
}

locals {
  layers = ["infra", "apps", "data", "observability"]
}

# Per-layer state buckets for security isolation
resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(local.layers)

  bucket = "keystone-${each.key}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project     = "keystone"
    Region      = "eu-north-1"
    Environment = "dev"
    Layer       = each.key
    Module      = "s3"
    ManagedBy   = "terraform"
    Name        = "keystone-${each.key}-terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_access" {
  for_each = aws_s3_bucket.terraform_state

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_names" {
  description = "Map of layer names to their state bucket names"
  value = {
    for layer, bucket in aws_s3_bucket.terraform_state : layer => bucket.bucket
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    # Retain older versions of the state file for 30 days to enable rollbacks
    # Production environments should consider 60-90 days for delayed bug discovery
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Clean up any incomplete uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
