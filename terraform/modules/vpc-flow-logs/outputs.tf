output "firehose_stream_arn" {
  description = "The ARN of the Kinesis Firehose delivery stream"
  value       = var.enable_flow_logs ? aws_kinesis_firehose_delivery_stream.vpc_flow_logs[0].arn : null
}

output "backup_bucket_id" {
  description = "The ID of the S3 backup bucket"
  value       = var.enable_flow_logs ? aws_s3_bucket.vpc_flow_logs_backup[0].id : null
}
