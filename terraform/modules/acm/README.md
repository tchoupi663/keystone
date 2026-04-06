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
| [aws_acm_certificate.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name for the certificate | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod, preprod) | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_validation_record_fqdns"></a> [validation\_record\_fqdns](#input\_validation\_record\_fqdns) | List of FQDNs for DNS validation records | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | The ARN of the validated ACM certificate |
| <a name="output_domain_validation_options"></a> [domain\_validation\_options](#output\_domain\_validation\_options) | Domain validation options for Route53 records |
| <a name="output_unvalidated_certificate_arn"></a> [unvalidated\_certificate\_arn](#output\_unvalidated\_certificate\_arn) | The ARN of the unvalidated ACM certificate |
