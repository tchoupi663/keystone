
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = var.enable_internet_gateway ? aws_internet_gateway.internet_gateway[0].id : null
}

output "nat_gateway_ips" {
  description = "Public Elastic IPs of the NAT Gateways"
  value       = aws_eip.nat_eip[*].public_ip
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.subnet_public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.subnet_private[*].cidr_block
}

output "database_subnets" {
  description = "IDs of database subnets"
  value       = aws_subnet.subnet_database[*].id
}

output "database_subnet_group_name" {
  description = "Name of the RDS DB Subnet Group"
  value       = var.database_subnets_count > 0 && var.create_database_subnet_group ? aws_db_subnet_group.database[0].name : null
}

output "availability_zones" {
  description = "List of AZs used by this VPC"
  value       = data.aws_availability_zones.available.names
}

output "default_security_group_id" {
  description = "ID of the default (restricted) security group"
  value       = aws_default_security_group.default.id
}

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC Gateway Endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = aws_subnet.subnet_public[*].id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = aws_subnet.subnet_private[*].id
}

output "public_rt" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_rt" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_public" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.nat_gateway_public[*].id
}