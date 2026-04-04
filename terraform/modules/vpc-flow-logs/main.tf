# S3 Backup for failed Firehose delivery
resource "aws_s3_bucket" "vpc_flow_logs_backup" {
  count         = var.enable_flow_logs ? 1 : 0
  bucket_prefix = "${var.project}-${var.environment}-flow-logs-backup-"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs_backup" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs_backup[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_backup" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs_backup[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_backup" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs_backup[0].id

  rule {
    id     = "expire-old-flow-log-backups"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# IAM Role for Firehose -> S3 backup
resource "aws_iam_role" "firehose_delivery_role" {
  count       = var.enable_flow_logs ? 1 : 0
  name_prefix = "${var.environment}-firehose-loki-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "firehose.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "firehose_delivery_policy" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "firehose_delivery_policy"
  role  = aws_iam_role.firehose_delivery_role[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.vpc_flow_logs_backup[0].arn,
          "${aws_s3_bucket.vpc_flow_logs_backup[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:PutLogEvents"]
        Resource = [
          "${aws_cloudwatch_log_group.firehose_errors[0].arn}:*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group for Firehose delivery errors
resource "aws_cloudwatch_log_group" "firehose_errors" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/firehose/${var.environment}-vpc-flow-logs"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_stream" "firehose_errors" {
  count          = var.enable_flow_logs ? 1 : 0
  name           = "DeliveryErrors"
  log_group_name = aws_cloudwatch_log_group.firehose_errors[0].name
}

# Firehose Delivery Stream to Grafana Cloud Loki HTTP endpoint
resource "aws_kinesis_firehose_delivery_stream" "vpc_flow_logs" {
  count       = var.enable_flow_logs ? 1 : 0
  name        = "${var.environment}-vpc-flow-logs-to-grafana"
  destination = "http_endpoint"

  tags = merge(local.common_tags, {
    LogDeliveryEnabled = "true"
  })

  http_endpoint_configuration {
    url                = "https://aws-${var.flow_logs_loki_host}/aws-logs/api/v1/push"
    name               = "Grafana AWS Logs Destination"
    access_key         = "${var.flow_logs_loki_user}:${var.flow_logs_token}"
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_delivery_role[0].arn
    s3_backup_mode     = "FailedDataOnly"

    request_configuration {
      content_encoding = "GZIP"

      common_attributes {
        name  = "lbl_job"
        value = "vpc-flow-logs"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_errors[0].name
      log_stream_name = aws_cloudwatch_log_stream.firehose_errors[0].name
    }

    s3_configuration {
      role_arn           = aws_iam_role.firehose_delivery_role[0].arn
      bucket_arn         = aws_s3_bucket.vpc_flow_logs_backup[0].arn
      buffering_size     = 5
      buffering_interval = 300
      compression_format = "GZIP"
    }
  }
}

# VPC Flow Log Resource
resource "aws_flow_log" "vpc" {
  count                = var.enable_flow_logs ? 1 : 0
  log_destination      = aws_kinesis_firehose_delivery_stream.vpc_flow_logs[0].arn
  log_destination_type = "kinesis-data-firehose"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

  tags = local.common_tags
}
