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
| [aws_autoscaling_group.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_db_subnet_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.nat_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_iam_instance_profile.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.fck_nat_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_launch_template.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_nat_gateway.nat_gateway_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_interface.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route.private_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.vpc_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.subnet_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.subnet_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.subnet_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | CIDR block for the VPC (e.g., 10.0.0.0/16) | `string` | `"10.0.0.0/16"` | no |
| <a name="input_connectivity_type"></a> [connectivity\_type](#input\_connectivity\_type) | Connectivity type for the NAT gateway | `string` | `"public"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Create an RDS DB Subnet Group from the database subnets | `bool` | `true` | no |
| <a name="input_database_subnets_count"></a> [database\_subnets\_count](#input\_database\_subnets\_count) | Number of isolated database subnets (no internet route). Should match AZ count for RDS Multi-AZ | `number` | `0` | no |
| <a name="input_enable_custom_nacls"></a> [enable\_custom\_nacls](#input\_enable\_custom\_nacls) | Deploy custom Network ACLs for public and private subnets with explicit allow rules | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Enable DNS hostnames | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Enable DNS support | `bool` | `true` | no |
| <a name="input_enable_internet_gateway"></a> [enable\_internet\_gateway](#input\_enable\_internet\_gateway) | Enable internet gateway | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Enable NAT gateway | `bool` | `true` | no |
| <a name="input_enable_s3_endpoint"></a> [enable\_s3\_endpoint](#input\_enable\_s3\_endpoint) | Provision a free S3 Gateway Endpoint to avoid NAT charges for S3 traffic | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (used in resource naming and tagging) | `string` | n/a | yes |
| <a name="input_ha_mode"></a> [ha\_mode](#input\_ha\_mode) | Enable high-availability mode for EC2 NAT gateway | `bool` | `true` | no |
| <a name="input_interface_endpoint_services"></a> [interface\_endpoint\_services](#input\_interface\_endpoint\_services) | Set of AWS service names to create Interface VPC Endpoints for (e.g., ecr.api, ecr.dkr, sts, logs, monitoring) | `set(string)` | `[]` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Enable public IP on launch | `bool` | `true` | no |
| <a name="input_nat_instance_type"></a> [nat\_instance\_type](#input\_nat\_instance\_type) | EC2 instance type for NAT gateway | `string` | `"t4g.nano"` | no |
| <a name="input_nat_type"></a> [nat\_type](#input\_nat\_type) | Type of NAT to use: 'gateway' for AWS NAT Gateway (~$32/mo), 'instance' for fck-nat EC2 (~$3/mo) | `string` | `"gateway"` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Should be true if you want only one NAT Gateway per availability zone. | `bool` | `false` | no |
| <a name="input_private_subnets_count"></a> [private\_subnets\_count](#input\_private\_subnets\_count) | Number of private subnets | `number` | `1` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name for tagging and resource identification | `string` | `"keystone"` | no |
| <a name="input_public_subnets_count"></a> [public\_subnets\_count](#input\_public\_subnets\_count) | Number of public subnets | `number` | `1` | no |
| <a name="input_region"></a> [region](#input\_region) | Define the region | `string` | n/a | yes |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_update_route_tables"></a> [update\_route\_tables](#input\_update\_route\_tables) | Update route tables for NAT gateway | `bool` | `true` | no |
| <a name="input_use_cloudwatch_agent"></a> [use\_cloudwatch\_agent](#input\_use\_cloudwatch\_agent) | Enable CloudWatch agent for NAT gateway | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | List of AZs used by this VPC |
| <a name="output_database_subnet_group_name"></a> [database\_subnet\_group\_name](#output\_database\_subnet\_group\_name) | Name of the RDS DB Subnet Group |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | IDs of database subnets |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | ID of the default (restricted) security group |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | Internet Gateway ID |
| <a name="output_nat_gateway_ips"></a> [nat\_gateway\_ips](#output\_nat\_gateway\_ips) | Public Elastic IPs of the NAT Gateways |
| <a name="output_nat_gateway_public"></a> [nat\_gateway\_public](#output\_nat\_gateway\_public) | IDs of the NAT Gateways |
| <a name="output_private_rt"></a> [private\_rt](#output\_private\_rt) | IDs of the private route tables |
| <a name="output_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#output\_private\_subnet\_cidrs) | CIDR blocks of private subnets |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | IDs of the private subnets |
| <a name="output_public_rt"></a> [public\_rt](#output\_public\_rt) | ID of the public route table |
| <a name="output_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#output\_public\_subnet\_cidrs) | CIDR blocks of public subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | IDs of the public subnets |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_endpoint_s3_id"></a> [vpc\_endpoint\_s3\_id](#output\_vpc\_endpoint\_s3\_id) | ID of the S3 VPC Gateway Endpoint |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
