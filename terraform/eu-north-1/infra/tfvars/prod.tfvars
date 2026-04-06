
environment = "prod"

cidr_block             = "10.0.0.0/16"
public_subnets_count   = 2
private_subnets_count  = 2

# VPC Configuration
enable_dns_hostnames         = true
enable_dns_support           = true
map_public_ip_on_launch      = false
connectivity_type            = "public"
enable_internet_gateway      = true
enable_nat_gateway           = true
nat_type                     = "instance"
single_nat_gateway           = true
one_nat_gateway_per_az       = false
create_database_subnet_group = false
enable_custom_nacls          = true
enable_s3_endpoint           = true
interface_endpoint_services  = []
enable_flow_logs             = true

# ECS Configuration
enable_container_insights = true
