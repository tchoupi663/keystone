## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_scheduled_action.scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_scheduled_action.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_target.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.alloy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.cloudflared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.secrets_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_execution_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group_rule.rds_ingress_from_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alloy_image_version"></a> [alloy\_image\_version](#input\_alloy\_image\_version) | Grafana Alloy Docker image version | `string` | `"v1.14.2"` | no |
| <a name="input_app_image"></a> [app\_image](#input\_app\_image) | Full Docker image URI (e.g. 123456789.dkr.ecr.eu-north-1.amazonaws.com/app:latest). If null, uses the ECR repository created by this module. | `string` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP to ECS tasks. Set to false when tasks run in private subnets behind NAT. | `bool` | `false` | no |
| <a name="input_capacity_provider_strategy"></a> [capacity\_provider\_strategy](#input\_capacity\_provider\_strategy) | Capacity provider strategy for the ECS service. When set, launch\_type is omitted. Each object must have 'capacity\_provider' and optionally 'weight' and 'base'. | <pre>list(object({<br/>    capacity_provider = string<br/>    weight            = optional(number, 1)<br/>    base              = optional(number, 0)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "base": 0,<br/>    "capacity_provider": "FARGATE",<br/>    "weight": 1<br/>  }<br/>]</pre> | no |
| <a name="input_cloudflare_tunnel_token_secret_arn"></a> [cloudflare\_tunnel\_token\_secret\_arn](#input\_cloudflare\_tunnel\_token\_secret\_arn) | ARN of the Secrets Manager secret holding the Cloudflare Tunnel token | `string` | n/a | yes |
| <a name="input_cloudflared_image_version"></a> [cloudflared\_image\_version](#input\_cloudflared\_image\_version) | Cloudflare Tunnel (cloudflared) Docker image version | `string` | `"2026.3.0"` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Port the container listens on | `number` | `80` | no |
| <a name="input_cpu_scaling_target"></a> [cpu\_scaling\_target](#input\_cpu\_scaling\_target) | Target CPU utilisation percentage for auto-scaling | `number` | `70` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | RDS endpoint hostname (without port) | `string` | `null` | no |
| <a name="input_db_master_user_secret_arn"></a> [db\_master\_user\_secret\_arn](#input\_db\_master\_user\_secret\_arn) | ARN of the Secrets Manager secret containing the RDS master user credentials | `string` | `null` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the database to connect to | `string` | `null` | no |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Port the database listens on | `number` | `5432` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of ECS tasks to run | `number` | `1` | no |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | ID of the ECS cluster to deploy the service to | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the ECS cluster | `string` | n/a | yes |
| <a name="input_ecs_security_group_id"></a> [ecs\_security\_group\_id](#input\_ecs\_security\_group\_id) | Security group ID for ECS tasks | `string` | n/a | yes |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Enable auto-scaling for the ECS service | `bool` | `false` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Enable ECS Exec (SSM-based shell access into containers) — useful for debugging. WARNING: Should NEVER be set to true in production environments. | `bool` | `false` | no |
| <a name="input_enable_scheduled_scaling"></a> [enable\_scheduled\_scaling](#input\_enable\_scheduled\_scaling) | Enable scheduled scaling for the ECS service | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g. dev, staging, prod) | `string` | n/a | yes |
| <a name="input_github_token_secret_arn"></a> [github\_token\_secret\_arn](#input\_github\_token\_secret\_arn) | ARN of the AWS Secrets Manager secret containing the GitHub Packages access token (JSON with username and password keys) | `string` | n/a | yes |
| <a name="input_grafana_loki_api_key_secret_arn"></a> [grafana\_loki\_api\_key\_secret\_arn](#input\_grafana\_loki\_api\_key\_secret\_arn) | ARN of the AWS Secrets Manager secret that holds the Grafana Cloud API key (the Loki basic-auth password). The secret value should be the raw API key string, not JSON. | `string` | n/a | yes |
| <a name="input_grafana_loki_host_ssm_arn"></a> [grafana\_loki\_host\_ssm\_arn](#input\_grafana\_loki\_host\_ssm\_arn) | SSM ARN of the Grafana Cloud Loki host. | `string` | n/a | yes |
| <a name="input_grafana_loki_user_ssm_arn"></a> [grafana\_loki\_user\_ssm\_arn](#input\_grafana\_loki\_user\_ssm\_arn) | SSM ARN of the Grafana Cloud Loki numeric user ID. | `string` | n/a | yes |
| <a name="input_grafana_prometheus_url_ssm_arn"></a> [grafana\_prometheus\_url\_ssm\_arn](#input\_grafana\_prometheus\_url\_ssm\_arn) | SSM ARN of the Grafana Cloud Prometheus remote-write URL. | `string` | n/a | yes |
| <a name="input_grafana_prometheus_user_ssm_arn"></a> [grafana\_prometheus\_user\_ssm\_arn](#input\_grafana\_prometheus\_user\_ssm\_arn) | SSM ARN of the Grafana Cloud Prometheus numeric user ID. | `string` | n/a | yes |
| <a name="input_grafana_tempo_endpoint_ssm_arn"></a> [grafana\_tempo\_endpoint\_ssm\_arn](#input\_grafana\_tempo\_endpoint\_ssm\_arn) | SSM ARN of the Grafana Cloud Tempo remote-write URL. | `string` | n/a | yes |
| <a name="input_grafana_tempo_user_ssm_arn"></a> [grafana\_tempo\_user\_ssm\_arn](#input\_grafana\_tempo\_user\_ssm\_arn) | SSM ARN of the Grafana Cloud Tempo numeric user ID. | `string` | n/a | yes |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | The approximate amount of time, in seconds, between health checks of an individual container. | `number` | `30` | no |
| <a name="input_health_check_retries"></a> [health\_check\_retries](#input\_health\_check\_retries) | The number of times to retry a failed health check before the container is considered unhealthy. | `number` | `3` | no |
| <a name="input_health_check_start_period"></a> [health\_check\_start\_period](#input\_health\_check\_start\_period) | The optional grace period within which to provide containers time to bootstrap before failed health checks count towards the maximum number of retries. | `number` | `60` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | The amount of time, in seconds, to wait when expecting a response from a health check. | `number` | `5` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | Maximum number of tasks when auto-scaling is enabled | `number` | `4` | no |
| <a name="input_memory_scaling_target"></a> [memory\_scaling\_target](#input\_memory\_scaling\_target) | Target memory utilisation percentage for auto-scaling | `number` | `80` | no |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | Minimum number of tasks when auto-scaling is enabled | `number` | `1` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_rds_security_group_id"></a> [rds\_security\_group\_id](#input\_rds\_security\_group\_id) | Security group ID of the RDS instance (ECS tasks will be allowed ingress) | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_scale_down_cron"></a> [scale\_down\_cron](#input\_scale\_down\_cron) | Cron expression for scaling down (e.g., '0 22 * * ? *' for 10 PM) | `string` | `"0 22 * * ? *"` | no |
| <a name="input_scale_down_max_capacity"></a> [scale\_down\_max\_capacity](#input\_scale\_down\_max\_capacity) | Maximum capacity during scale down period | `number` | `0` | no |
| <a name="input_scale_down_min_capacity"></a> [scale\_down\_min\_capacity](#input\_scale\_down\_min\_capacity) | Minimum capacity during scale down period | `number` | `0` | no |
| <a name="input_scale_up_cron"></a> [scale\_up\_cron](#input\_scale\_up\_cron) | Cron expression for scaling up (e.g., '0 8 * * ? *' for 8 AM) | `string` | `"0 8 * * ? *"` | no |
| <a name="input_scale_up_max_capacity"></a> [scale\_up\_max\_capacity](#input\_scale\_up\_max\_capacity) | Maximum capacity during scale up period | `number` | `4` | no |
| <a name="input_scale_up_min_capacity"></a> [scale\_up\_min\_capacity](#input\_scale\_up\_min\_capacity) | Minimum capacity during scale up period | `number` | `1` | no |
| <a name="input_scaling_scale_in_cooldown"></a> [scaling\_scale\_in\_cooldown](#input\_scaling\_scale\_in\_cooldown) | The amount of time, in seconds, after a scale in activity completes before another scale in activity can start. | `number` | `300` | no |
| <a name="input_scaling_scale_out_cooldown"></a> [scaling\_scale\_out\_cooldown](#input\_scaling\_scale\_out\_cooldown) | The amount of time, in seconds, after a scale out activity completes before another scale out activity can start. | `number` | `60` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs where ECS tasks run (private subnets when using NAT) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | CPU units for the Fargate task (256 = 0.25 vCPU) | `string` | `"512"` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Memory (MiB) for the Fargate task | `string` | `"1024"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where ECS resources are deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | ARN of the ECS task execution role |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the CloudWatch log group for the ECS service |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ID of the ECS service |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the ECS service |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | ARN of the current task definition |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Family of the task definition |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | ARN of the ECS task role |
