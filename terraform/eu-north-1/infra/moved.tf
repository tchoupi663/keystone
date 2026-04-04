moved {
  from = module.vpc.aws_s3_bucket.vpc_flow_logs_backup[0]
  to   = module.vpc_flow_logs.aws_s3_bucket.vpc_flow_logs_backup[0]
}

moved {
  from = module.vpc.aws_s3_bucket_versioning.vpc_flow_logs_backup[0]
  to   = module.vpc_flow_logs.aws_s3_bucket_versioning.vpc_flow_logs_backup[0]
}

moved {
  from = module.vpc.aws_s3_bucket_public_access_block.vpc_flow_logs_backup[0]
  to   = module.vpc_flow_logs.aws_s3_bucket_public_access_block.vpc_flow_logs_backup[0]
}

moved {
  from = module.vpc.aws_s3_bucket_lifecycle_configuration.vpc_flow_logs_backup[0]
  to   = module.vpc_flow_logs.aws_s3_bucket_lifecycle_configuration.vpc_flow_logs_backup[0]
}

moved {
  from = module.vpc.aws_iam_role.firehose_delivery_role[0]
  to   = module.vpc_flow_logs.aws_iam_role.firehose_delivery_role[0]
}

moved {
  from = module.vpc.aws_iam_role_policy.firehose_delivery_policy[0]
  to   = module.vpc_flow_logs.aws_iam_role_policy.firehose_delivery_policy[0]
}

moved {
  from = module.vpc.aws_cloudwatch_log_group.firehose_errors[0]
  to   = module.vpc_flow_logs.aws_cloudwatch_log_group.firehose_errors[0]
}

moved {
  from = module.vpc.aws_cloudwatch_log_stream.firehose_errors[0]
  to   = module.vpc_flow_logs.aws_cloudwatch_log_stream.firehose_errors[0]
}

moved {
  from = module.vpc.aws_kinesis_firehose_delivery_stream.vpc_flow_logs[0]
  to   = module.vpc_flow_logs.aws_kinesis_firehose_delivery_stream.vpc_flow_logs[0]
}

moved {
  from = module.vpc.aws_flow_log.vpc[0]
  to   = module.vpc_flow_logs.aws_flow_log.vpc[0]
}
