## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_ruleset.custom_waf](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_ruleset.http_to_https_redirect](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_ruleset.rate_limit_leaked_credentials](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_zero_trust_access_identity_provider.otp](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider) | resource |
| [cloudflare_zero_trust_access_mtls_hostname_settings.account](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_hostname_settings) | resource |
| [cloudflare_zero_trust_device_posture_rule.gateway](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_posture_rule) | resource |
| [cloudflare_zero_trust_device_posture_rule.warp](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_posture_rule) | resource |
| [cloudflare_zero_trust_gateway_policy.policies](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_gateway_policy) | resource |
| [cloudflare_zero_trust_gateway_settings.account](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_gateway_settings) | resource |
| [cloudflare_zero_trust_organization.account](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_organization) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_account_id"></a> [cloudflare\_account\_id](#input\_cloudflare\_account\_id) | Cloudflare Account ID | `string` | n/a | yes |
| <a name="input_cloudflare_zone_id"></a> [cloudflare\_zone\_id](#input\_cloudflare\_zone\_id) | Cloudflare Zone ID | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Top-level domain name | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g. dev, prod) | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | List of subdomains for the application | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_waf_custom_rules"></a> [waf\_custom\_rules](#input\_waf\_custom\_rules) | Custom WAF Firewall Rules | <pre>list(object({<br/>    name        = string<br/>    action      = string<br/>    enabled     = optional(bool, true)<br/>    expression  = string<br/>    description = optional(string, "")<br/>  }))</pre> | `[]` | no |
| <a name="input_waf_rate_limit_rules"></a> [waf\_rate\_limit\_rules](#input\_waf\_rate\_limit\_rules) | Custom WAF Rate Limit Rules | <pre>list(object({<br/>    name        = string<br/>    action      = string<br/>    enabled     = optional(bool, true)<br/>    expression  = string<br/>    description = optional(string, "")<br/>    ratelimit = object({<br/>      characteristics     = list(string)<br/>      mitigation_timeout  = number<br/>      period              = number<br/>      requests_per_period = number<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_zero_trust_gateway_policy"></a> [zero\_trust\_gateway\_policy](#input\_zero\_trust\_gateway\_policy) | Zero Trust Gateway Policies | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    action      = string<br/>    enabled     = optional(bool, true)<br/>    filters     = list(string)<br/>    traffic     = string<br/>    precedence  = number<br/>    rule_settings = optional(object({<br/>      notification_settings = optional(object({<br/>        enabled = bool<br/>        msg     = string<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_identity_provider_id"></a> [access\_identity\_provider\_id](#output\_access\_identity\_provider\_id) | The ID of the Zero Trust Access Identity Provider |
| <a name="output_zero_trust_organization_id"></a> [zero\_trust\_organization\_id](#output\_zero\_trust\_organization\_id) | The ID of the Zero Trust Organization |
