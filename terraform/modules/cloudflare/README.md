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
| [cloudflare_dns_record.root](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_dns_record.subdomain_cnames](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_email_routing_catch_all.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/email_routing_catch_all) | resource |
| [cloudflare_managed_transforms.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/managed_transforms) | resource |
| [cloudflare_page_rule.subdomain_browser_cache](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/page_rule) | resource |
| [cloudflare_ruleset.custom_waf](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_ruleset.http_to_https_redirect](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_ruleset.rate_limit_leaked_credentials](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [cloudflare_tiered_cache.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tiered_cache) | resource |
| [cloudflare_zero_trust_access_identity_provider.otp](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_identity_provider) | resource |
| [cloudflare_zero_trust_access_mtls_hostname_settings.account](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_access_mtls_hostname_settings) | resource |
| [cloudflare_zero_trust_device_posture_rule.gateway](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_posture_rule) | resource |
| [cloudflare_zero_trust_device_posture_rule.warp](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_device_posture_rule) | resource |
| [cloudflare_zero_trust_gateway_policy.policies](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_gateway_policy) | resource |
| [cloudflare_zero_trust_gateway_settings.account](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_gateway_settings) | resource |
| [cloudflare_zero_trust_organization.account](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_organization) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_config.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared_config) | resource |
| [random_password.tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_account_id"></a> [cloudflare\_account\_id](#input\_cloudflare\_account\_id) | Cloudflare Account ID | `string` | n/a | yes |
| <a name="input_cloudflare_zone_id"></a> [cloudflare\_zone\_id](#input\_cloudflare\_zone\_id) | Cloudflare Zone ID | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Top-level domain name | `string` | n/a | yes |
| <a name="input_email_routing_catch_all_enabled"></a> [email\_routing\_catch\_all\_enabled](#input\_email\_routing\_catch\_all\_enabled) | Is Email Routing catch-all enabled? | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g. dev, prod) | `string` | n/a | yes |
| <a name="input_managed_transforms"></a> [managed\_transforms](#input\_managed\_transforms) | Managed Request/Response Headers configuration | <pre>object({<br/>    request_headers = list(object({<br/>      id      = string<br/>      enabled = bool<br/>    }))<br/>    response_headers = list(object({<br/>      id      = string<br/>      enabled = bool<br/>    }))<br/>  })</pre> | <pre>{<br/>  "request_headers": [<br/>    {<br/>      "enabled": true,<br/>      "id": "add_client_certificate_headers"<br/>    },<br/>    {<br/>      "enabled": true,<br/>      "id": "add_visitor_location_headers"<br/>    },<br/>    {<br/>      "enabled": true,<br/>      "id": "remove_visitor_ip_headers"<br/>    },<br/>    {<br/>      "enabled": true,<br/>      "id": "add_waf_credential_check_status_header"<br/>    }<br/>  ],<br/>  "response_headers": [<br/>    {<br/>      "enabled": true,<br/>      "id": "remove_x-powered-by_header"<br/>    },<br/>    {<br/>      "enabled": true,<br/>      "id": "add_security_headers"<br/>    }<br/>  ]<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Define the region | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | List of subdomains for the application | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tiered_cache"></a> [tiered\_cache](#input\_tiered\_cache) | Tiered Cache value | `string` | `"off"` | no |
| <a name="input_tunnel_origin_port"></a> [tunnel\_origin\_port](#input\_tunnel\_origin\_port) | Port the tunnel sidecar should connect to (internal app port) | `number` | `8080` | no |
| <a name="input_waf_custom_rules"></a> [waf\_custom\_rules](#input\_waf\_custom\_rules) | Custom WAF Firewall Rules | <pre>list(object({<br/>    name        = string<br/>    action      = string<br/>    enabled     = optional(bool, true)<br/>    expression  = string<br/>    description = optional(string, "")<br/>  }))</pre> | `[]` | no |
| <a name="input_waf_rate_limit_rules"></a> [waf\_rate\_limit\_rules](#input\_waf\_rate\_limit\_rules) | Custom WAF Rate Limit Rules | <pre>list(object({<br/>    name        = string<br/>    action      = string<br/>    enabled     = optional(bool, true)<br/>    expression  = string<br/>    description = optional(string, "")<br/>    ratelimit = object({<br/>      characteristics     = list(string)<br/>      mitigation_timeout  = number<br/>      period              = number<br/>      requests_per_period = number<br/>    })<br/>  }))</pre> | <pre>[<br/>  {<br/>    "action": "block",<br/>    "description": "Leaked credential check",<br/>    "enabled": true,<br/>    "expression": "(cf.waf.credential_check.password_leaked)",<br/>    "name": "Leaked Credential Check",<br/>    "ratelimit": {<br/>      "characteristics": [<br/>        "ip.src",<br/>        "cf.colo.id"<br/>      ],<br/>      "mitigation_timeout": 10,<br/>      "period": 10,<br/>      "requests_per_period": 5<br/>    }<br/>  }<br/>]</pre> | no |
| <a name="input_zero_trust_gateway_policy"></a> [zero\_trust\_gateway\_policy](#input\_zero\_trust\_gateway\_policy) | Zero Trust Gateway Policies | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    action      = string<br/>    enabled     = optional(bool, true)<br/>    filters     = list(string)<br/>    traffic     = string<br/>    precedence  = number<br/>    rule_settings = optional(object({<br/>      notification_settings = optional(object({<br/>        enabled = bool<br/>        msg     = string<br/>      }))<br/>    }))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "action": "off",<br/>    "description": "This policy excludes from inspection applications which are known to have desktop apps with certificate pinning.",<br/>    "enabled": true,<br/>    "filters": [<br/>      "http"<br/>    ],<br/>    "name": "Do Not Inspect",<br/>    "precedence": 0,<br/>    "traffic": "any(app.type.ids[*] in {16})"<br/>  },<br/>  {<br/>    "action": "block",<br/>    "description": "A catch-all policy to block all private traffic destined for the RFC1918 address space.",<br/>    "enabled": true,<br/>    "filters": [<br/>      "l4"<br/>    ],<br/>    "name": "Default deny for private traffic",<br/>    "precedence": 10000,<br/>    "rule_settings": {<br/>      "notification_settings": {<br/>        "enabled": true,<br/>        "msg": "This connection has been blocked by your account default-deny network policy."<br/>      }<br/>    },<br/>    "traffic": "net.dst.ip in {10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.96.0.0/12}"<br/>  }<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tunnel_cname"></a> [tunnel\_cname](#output\_tunnel\_cname) | CNAME target for the tunnel |
| <a name="output_tunnel_id"></a> [tunnel\_id](#output\_tunnel\_id) | ID of the Cloudflare Tunnel |
| <a name="output_tunnel_name"></a> [tunnel\_name](#output\_tunnel\_name) | Name of the Cloudflare Tunnel |
| <a name="output_tunnel_token_secret_arn"></a> [tunnel\_token\_secret\_arn](#output\_tunnel\_token\_secret\_arn) | ARN of the AWS Secret containing the Cloudflare Tunnel token |
