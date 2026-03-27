provider "aws" {
  region = "eu-north-1"
}

# Provider for DR region
provider "aws" {
  alias  = "dr"
  region = "eu-west-1"
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

# ──────────────────────────────────────────────
# Cross-Region Replication for Disaster Recovery
# ──────────────────────────────────────────────
# Replicate Terraform state to eu-west-1 for resilience against regional outages

# Replica buckets in DR region (eu-west-1)
resource "aws_s3_bucket" "terraform_state_replica" {
  for_each = toset(local.layers)
  provider = aws.dr

  bucket = "keystone-${each.key}-terraform-state-replica"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project     = "keystone"
    Region      = "eu-west-1"
    Environment = "dev"
    Layer       = each.key
    Module      = "s3"
    ManagedBy   = "terraform"
    Purpose     = "disaster-recovery-replica"
    Name        = "keystone-${each.key}-terraform-state-replica"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_replica_versioning" {
  for_each = aws_s3_bucket.terraform_state_replica
  provider = aws.dr

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_replica_crypto" {
  for_each = aws_s3_bucket.terraform_state_replica
  provider = aws.dr

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_replica_access" {
  for_each = aws_s3_bucket.terraform_state_replica
  provider = aws.dr

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for S3 replication
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "replication" {
  name = "keystone-terraform-state-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project   = "keystone"
    ManagedBy = "terraform"
    Purpose   = "s3-cross-region-replication"
  }
}

resource "aws_iam_policy" "replication" {
  name = "keystone-terraform-state-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          for bucket in aws_s3_bucket.terraform_state : bucket.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          for bucket in aws_s3_bucket.terraform_state : "${bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          for bucket in aws_s3_bucket.terraform_state_replica : "${bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Replication configuration for each primary bucket
resource "aws_s3_bucket_replication_configuration" "terraform_state_replication" {
  for_each = aws_s3_bucket.terraform_state

  # Must have bucket versioning enabled before replication can be configured
  depends_on = [aws_s3_bucket_versioning.terraform_state_versioning]

  role   = aws_iam_role.replication.arn
  bucket = each.value.id

  rule {
    id     = "replicate-all-to-dr-region"
    status = "Enabled"

    filter {}

    destination {
      bucket        = aws_s3_bucket.terraform_state_replica[each.key].arn
      storage_class = "STANDARD_IA" # Infrequent Access for cost optimization

      # Replicate metadata
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      # Track replication metrics
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

output "state_bucket_replica_names" {
  description = "Map of layer names to their DR replica bucket names"
  value = {
    for layer, bucket in aws_s3_bucket.terraform_state_replica : layer => bucket.bucket
  }
}
