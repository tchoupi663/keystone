## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.tunnel_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.tunnel_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_config.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared_config) | resource |
| [random_password.tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_account_id"></a> [cloudflare\_account\_id](#input\_cloudflare\_account\_id) | Cloudflare Account ID | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Top-level domain name | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g. dev, prod) | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | List of subdomains for the application | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tunnel_origin_port"></a> [tunnel\_origin\_port](#input\_tunnel\_origin\_port) | Port the tunnel sidecar should connect to (internal app port) | `number` | `8080` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tunnel_cname"></a> [tunnel\_cname](#output\_tunnel\_cname) | The CNAME target for the Cloudflare Tunnel |
| <a name="output_tunnel_id"></a> [tunnel\_id](#output\_tunnel\_id) | The ID of the Cloudflare Tunnel |
| <a name="output_tunnel_name"></a> [tunnel\_name](#output\_tunnel\_name) | The name of the Cloudflare Tunnel |
| <a name="output_tunnel_token_secret_arn"></a> [tunnel\_token\_secret\_arn](#output\_tunnel\_token\_secret\_arn) | The ARN of the AWS Secrets Manager secret containing the tunnel token |
