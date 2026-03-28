module "vpc" {
  source = "../../modules/vpc"

  region      = var.region
  environment = var.environment
  project     = var.project

  cidr_block = var.cidr_block

  public_subnets_count  = var.public_subnets_count
  private_subnets_count = var.private_subnets_count

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true
  connectivity_type       = "public"

  enable_internet_gateway = true

  # NAT disabled - ECS tasks now run in public subnets with public IPs,
  # outbound traffic goes directly through the IGW.
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  database_subnets_count       = var.database_subnets_count
  create_database_subnet_group = true

  enable_custom_nacls = true

  enable_s3_endpoint = true

  interface_endpoint_services = []
}

# ──────────────────────────────────────────────
# ECS Security Group
# ──────────────────────────────────────────────
# With Cloudflare Tunnel, there is NO inbound traffic from the internet.
# The cloudflared sidecar opens an outbound connection to Cloudflare's
# edge. Only egress rules are needed.
# ──────────────────────────────────────────────

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.environment}-ecs-tasks-"
  description = "ECS tasks - outbound only (Cloudflare Tunnel handles inbound)"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow RDS access within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    description = "Allow HTTPS for AWS APIs and Cloudflare Tunnel"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # cloudflared also uses port 7844 (QUIC) for tunnel connections
  egress {
    description = "Allow QUIC for Cloudflare Tunnel"
    from_port   = 7844
    to_port     = 7844
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  egress {
    description = "Allow QUIC and TCP fallbacks for Cloudflare Tunnel"
    from_port   = 7844
    to_port     = 7844
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }


module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment = var.environment
  project     = var.project

  enable_container_insights = true
}

# ──────────────────────────────────────────────
# VPC Flow Logs -> Kinesis Data Firehose -> Grafana Loki
# ──────────────────────────────────────────────

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "flow_logs_token" {
  name = "keystone/${var.environment}/flow-logs-token"
}

data "aws_secretsmanager_secret_version" "flow_logs_token" {
  secret_id = data.aws_secretsmanager_secret.flow_logs_token.id
}

# S3 Backup for failed Firehose delivery
resource "aws_s3_bucket" "vpc_flow_logs_backup" {
  bucket_prefix = "${var.project}-${var.environment}-flow-logs-backup-"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs_backup" {
  bucket = aws_s3_bucket.vpc_flow_logs_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_backup" {
  bucket = aws_s3_bucket.vpc_flow_logs_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Firehose → S3 backup
resource "aws_iam_role" "firehose_delivery_role" {
  name_prefix = "${var.environment}-firehose-loki-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = { Service = "firehose.amazonaws.com" }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_delivery_policy" {
  name   = "firehose_delivery_policy"
  role   = aws_iam_role.firehose_delivery_role.id
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
          aws_s3_bucket.vpc_flow_logs_backup.arn,
          "${aws_s3_bucket.vpc_flow_logs_backup.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:PutLogEvents"]
        Resource = ["*"]
      }
    ]
  })
}

# CloudWatch Log Group for Firehose delivery errors
resource "aws_cloudwatch_log_group" "firehose_errors" {
  name              = "/aws/firehose/${var.environment}-vpc-flow-logs"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_stream" "firehose_errors" {
  name           = "DeliveryErrors"
  log_group_name = aws_cloudwatch_log_group.firehose_errors.name
}

# Firehose Delivery Stream to Grafana Cloud Loki HTTP endpoint
resource "aws_kinesis_firehose_delivery_stream" "vpc_flow_logs" {
  name        = "${var.environment}-vpc-flow-logs-to-grafana"
  destination = "http_endpoint"

  tags = {
    Environment      = var.environment
    Project          = var.project
    ManagedBy        = "terraform"
    LogDeliveryEnabled = "true"
  }

  http_endpoint_configuration {
    url                = "https://aws-${var.grafana_loki_host}/aws-logs/api/v1/push"
    name               = "Grafana AWS Logs Destination"
    access_key         = "${var.grafana_loki_user}:${jsondecode(data.aws_secretsmanager_secret_version.flow_logs_token.secret_string)["aws-token"]}"
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_delivery_role.arn
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
      log_group_name  = aws_cloudwatch_log_group.firehose_errors.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_errors.name
    }

    s3_configuration {
      role_arn           = aws_iam_role.firehose_delivery_role.arn
      bucket_arn         = aws_s3_bucket.vpc_flow_logs_backup.arn
      buffering_size     = 5
      buffering_interval = 300
      compression_format = "GZIP"
    }
  }
}

# VPC Flow Log Resource
resource "aws_flow_log" "vpc" {
  log_destination      = aws_kinesis_firehose_delivery_stream.vpc_flow_logs.arn
  log_destination_type = "kinesis-data-firehose"
  traffic_type         = "ALL" 
  vpc_id               = module.vpc.vpc_id

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}