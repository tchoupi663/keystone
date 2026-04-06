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
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_iam_role.rds_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.rds_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_scheduler_schedule.start_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_scheduler_schedule.stop_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Storage size in GB | `number` | `20` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Allow major engine version upgrades (requires manual apply) | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Automatically apply minor engine upgrades during the maintenance window | `bool` | `true` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Number of days to retain automated backups (0 to disable) | `number` | `7` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Daily time range (UTC) for automated backups, must not overlap with maintenance\_window | `string` | `"03:00-04:00"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the default database to create | `string` | `"appdb"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Master password (only used when manage\_master\_user\_password = false). Must be >= 8 characters. | `string` | `null` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of the DB subnet group (created by the VPC module) | `string` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Master username for the database | `string` | `"dbadmin"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Prevent accidental deletion of the RDS instance | `bool` | `false` | no |
| <a name="input_enable_scheduled_scaling"></a> [enable\_scheduled\_scaling](#input\_enable\_scheduled\_scaling) | Enable scheduled starting and stopping of the RDS instance | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to export to CloudWatch (e.g. ["postgresql", "upgrade"] for postgres) | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine (e.g. postgres, mysql, mariadb) | `string` | `"postgres"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Major version of the database engine (e.g. 16 for PostgreSQL 16) | `string` | `"16"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod, preprod) | `string` | n/a | yes |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Name of the final snapshot (required when skip\_final\_snapshot = false) | `string` | `null` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | RDS instance class (e.g. db.t3.micro, db.t4g.micro) | `string` | `"db.t4g.micro"` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly time range (UTC) for system maintenance | `string` | `"sun:04:30-sun:05:30"` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Let RDS manage the master password via Secrets Manager (recommended). When true, db\_password is ignored. | `bool` | `true` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Enable Multi-AZ deployment for high availability | `bool` | `false` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Enable Performance Insights (free tier on db.t3/t4g.micro) | `bool` | `true` | no |
| <a name="input_port"></a> [port](#input\_port) | Port the database listens on (5432 for postgres, 3306 for mysql) | `number` | `5432` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name for tagging and resource identification | `string` | `"keystone"` | no |
| <a name="input_region"></a> [region](#input\_region) | Define the region | `string` | n/a | yes |
| <a name="input_scale_down_cron"></a> [scale\_down\_cron](#input\_scale\_down\_cron) | Cron expression for scaling down (stopping) the RDS instance (e.g. '15 20 * * ? *') | `string` | `"15 20 * * ? *"` | no |
| <a name="input_scale_up_cron"></a> [scale\_up\_cron](#input\_scale\_up\_cron) | Cron expression for scaling up (starting) the RDS instance (e.g. '45 6 * * ? *') | `string` | `"45 6 * * ? *"` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Skip final snapshot when the DB is deleted (set false in production) | `bool` | `true` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | The name of the snapshot (optional) to use when creating the DB instance. If provided, the DB will be restored from this snapshot. | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Enable encryption at rest (uses default aws/rds KMS key) | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Storage type (gp2, gp3, io1) | `string` | `"gp3"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the RDS instance will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_address"></a> [db\_address](#output\_db\_address) | Hostname of the RDS instance (without port) |
| <a name="output_db_endpoint"></a> [db\_endpoint](#output\_db\_endpoint) | Connection endpoint (host:port) |
| <a name="output_db_instance_arn"></a> [db\_instance\_arn](#output\_db\_instance\_arn) | ARN of the RDS instance |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | The RDS instance ID |
| <a name="output_db_master_user_secret_arn"></a> [db\_master\_user\_secret\_arn](#output\_db\_master\_user\_secret\_arn) | ARN of the Secrets Manager secret containing the master password (only set when manage\_master\_user\_password = true) |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | Name of the default database |
| <a name="output_db_port"></a> [db\_port](#output\_db\_port) | Port the database listens on |
| <a name="output_db_security_group_id"></a> [db\_security\_group\_id](#output\_db\_security\_group\_id) | ID of the security group attached to the RDS instance |
| <a name="output_db_username"></a> [db\_username](#output\_db\_username) | Master username |
