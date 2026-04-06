
environment = "dev"

cidr_block             = "10.0.0.0/16"
public_subnets_count   = 2
private_subnets_count  = 2
database_subnets_count = 2

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

# ALB Configuration
alb_internal                   = false
alb_enable_deletion_protection = false
alb_idle_timeout               = 60
alb_drop_invalid_header_fields = true
alb_enable_http2               = true
alb_ssl_policy                 = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
alb_target_group_port          = 80
alb_target_group_protocol      = "HTTP"
alb_target_type                = "ip"
alb_deregistration_delay       = 30
alb_health_check               = {}
alb_enable_access_logs         = true
alb_access_logs_bucket         = ""
alb_access_logs_prefix         = "alb-logs"
alb_ingress_cidr_blocks        = ["0.0.0.0/0"]

# ACM Configuration
acm_validation_record_fqdns = []