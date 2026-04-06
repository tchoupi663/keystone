## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.firehose_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.firehose_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_flow_log.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.firehose_delivery_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.firehose_delivery_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kinesis_firehose_delivery_stream.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_s3_bucket.vpc_flow_logs_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.vpc_flow_logs_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.vpc_flow_logs_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_versioning.vpc_flow_logs_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable VPC Flow Logs | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment | `string` | n/a | yes |
| <a name="input_flow_logs_loki_host"></a> [flow\_logs\_loki\_host](#input\_flow\_logs\_loki\_host) | Grafana Cloud Loki host for Firehose | `string` | `""` | no |
| <a name="input_flow_logs_loki_user"></a> [flow\_logs\_loki\_user](#input\_flow\_logs\_loki\_user) | Grafana user ID for Loki | `string` | `""` | no |
| <a name="input_flow_logs_token"></a> [flow\_logs\_token](#input\_flow\_logs\_token) | Grafana AWS token for Loki | `string` | `""` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource tags | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where flow logs will be enabled | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_bucket_id"></a> [backup\_bucket\_id](#output\_backup\_bucket\_id) | The ID of the S3 backup bucket |
| <a name="output_firehose_stream_arn"></a> [firehose\_stream\_arn](#output\_firehose\_stream\_arn) | The ARN of the Kinesis Firehose delivery stream |
