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
| [cloudflare_dns_record.root](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_dns_record.subdomain_cnames](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_email_routing_catch_all.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/email_routing_catch_all) | resource |
| [cloudflare_managed_transforms.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/managed_transforms) | resource |
| [cloudflare_page_rule.subdomain_browser_cache](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/page_rule) | resource |
| [cloudflare_tiered_cache.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tiered_cache) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_zone_id"></a> [cloudflare\_zone\_id](#input\_cloudflare\_zone\_id) | Cloudflare Zone ID | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Top-level domain name | `string` | n/a | yes |
| <a name="input_email_routing_catch_all_enabled"></a> [email\_routing\_catch\_all\_enabled](#input\_email\_routing\_catch\_all\_enabled) | Is Email Routing catch-all enabled? | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment | `string` | n/a | yes |
| <a name="input_managed_transforms"></a> [managed\_transforms](#input\_managed\_transforms) | Managed Request/Response Headers configuration | <pre>object({<br/>    request_headers = list(object({<br/>      id      = string<br/>      enabled = bool<br/>    }))<br/>    response_headers = list(object({<br/>      id      = string<br/>      enabled = bool<br/>    }))<br/>  })</pre> | <pre>{<br/>  "request_headers": [],<br/>  "response_headers": []<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | List of subdomains for the application | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tiered_cache"></a> [tiered\_cache](#input\_tiered\_cache) | Tiered Cache value | `string` | `"off"` | no |
| <a name="input_tunnel_id"></a> [tunnel\_id](#input\_tunnel\_id) | The ID of the Cloudflare Tunnel to point DNS records to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_record_root"></a> [dns\_record\_root](#output\_dns\_record\_root) | The DNS record name for the root domain |
| <a name="output_dns_records_subdomains"></a> [dns\_records\_subdomains](#output\_dns\_records\_subdomains) | The DNS record names for subdomains |
