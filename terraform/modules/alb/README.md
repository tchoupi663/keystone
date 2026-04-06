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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.blocked_paths](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.host_based](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_bucket"></a> [access\_logs\_bucket](#input\_access\_logs\_bucket) | S3 bucket name for ALB access logs (required when enable\_access\_logs = true) | `string` | `""` | no |
| <a name="input_access_logs_prefix"></a> [access\_logs\_prefix](#input\_access\_logs\_prefix) | S3 key prefix for ALB access logs | `string` | `"alb-logs"` | no |
| <a name="input_blocked_paths"></a> [blocked\_paths](#input\_blocked\_paths) | List of path patterns to block (returns 403 Forbidden) | `list(string)` | `[]` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate for the HTTPS listener | `string` | n/a | yes |
| <a name="input_deregistration_delay"></a> [deregistration\_delay](#input\_deregistration\_delay) | Time in seconds to wait before deregistering a target (allows in-flight requests to complete) | `number` | `30` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to point to ALB | `string` | n/a | yes |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Drop HTTP headers with invalid header fields (security best practice) | `bool` | `true` | no |
| <a name="input_ecs_sg_id"></a> [ecs\_sg\_id](#input\_ecs\_sg\_id) | Security group ID of the ECS tasks to allow outbound traffic from ALB | `string` | n/a | yes |
| <a name="input_enable_access_logs"></a> [enable\_access\_logs](#input\_enable\_access\_logs) | Enable ALB access logs to S3 | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Prevent accidental deletion of the ALB | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Enable HTTP/2 on the ALB | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod, preprod) | `string` | n/a | yes |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | Health check configuration for the target group | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    path                = optional(string, "/")<br/>    port                = optional(string, "traffic-port")<br/>    protocol            = optional(string, "HTTP")<br/>    healthy_threshold   = optional(number, 3)<br/>    unhealthy_threshold = optional(number, 3)<br/>    timeout             = optional(number, 5)<br/>    interval            = optional(number, 30)<br/>    matcher             = optional(string, "200")<br/>  })</pre> | `{}` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | Time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | CIDR blocks allowed to reach the ALB (defaults to the entire internet) | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_internal"></a> [internal](#input\_internal) | If true, the ALB is internal (not internet-facing) | `bool` | `false` | no |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Map of host-based listener rules. Each rule forwards traffic to the default target group when the Host header matches. Key is the rule name. | <pre>map(object({<br/>    priority     = number<br/>    host_headers = list(string) # e.g. ["app.example.com", "*.example.com"]<br/>  }))</pre> | `{}` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name for tagging and resource identification | `string` | `"keystone"` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnet IDs where the ALB will be placed (minimum 2 in different AZs) | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Define the region | `string` | n/a | yes |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | SSL policy for the HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_target_group_port"></a> [target\_group\_port](#input\_target\_group\_port) | Port on which targets receive traffic | `number` | `80` | no |
| <a name="input_target_group_protocol"></a> [target\_group\_protocol](#input\_target\_group\_protocol) | Protocol for the target group (HTTP or HTTPS) | `string` | `"HTTP"` | no |
| <a name="input_target_type"></a> [target\_type](#input\_target\_type) | Type of target (instance, ip, lambda). Use 'ip' for ECS Fargate tasks | `string` | `"ip"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR block of the VPC (used for ALB egress to targets) | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the ALB will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | The ARN of the ALB |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | The DNS name of the ALB (use for DNS CNAME / Route 53 alias) |
| <a name="output_alb_id"></a> [alb\_id](#output\_alb\_id) | The ID of the ALB |
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | ID of the security group attached to the ALB (reference in ECS task SG ingress rules) |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | The canonical hosted zone ID of the ALB (for Route 53 alias records) |
| <a name="output_http_listener_arn"></a> [http\_listener\_arn](#output\_http\_listener\_arn) | ARN of the HTTP listener |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | ARN of the HTTPS listener |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the default target group (attach ECS services here) |
| <a name="output_target_group_name"></a> [target\_group\_name](#output\_target\_group\_name) | Name of the default target group |
