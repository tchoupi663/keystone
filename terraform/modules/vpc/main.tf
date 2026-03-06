
# get available availability zones 
data "aws_availability_zones" "available" {
  state = "available"
}

# create vpc resource with dns support
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc-${var.region}"
  })
}

# public subnet 
resource "aws_subnet" "subnet_public" {
  count                   = var.public_subnets_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-${data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]}"
  })
}

# private subnet
resource "aws_subnet" "subnet_private" {
  count  = var.private_subnets_count
  vpc_id = aws_vpc.vpc.id

  # we add 8 bits to the VPC CIDR block for the subnet addresses (so e.g. if for vpc: 10.0.x.x/16, then for subnets: 10.0.0.x/24 -> ~65k hosts)
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index + var.public_subnets_count)
  # cycle through AZs for each subnet
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-${data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]}"
  })
}

# database subnet
resource "aws_subnet" "subnet_database" {
  count             = var.database_subnets_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + var.public_subnets_count + var.private_subnets_count)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-database-${data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]}"
    Tier = "database"
  })
}

# Dedicated route table with NO routes to internet for db subnets
resource "aws_route_table" "database" {
  count  = var.database_subnets_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-database-rt"
  })
}

# associate db subnets with db route table
resource "aws_route_table_association" "database" {
  count          = var.database_subnets_count
  subnet_id      = aws_subnet.subnet_database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# RDS Subnet Group — required by RDS, Aurora, etc.
resource "aws_db_subnet_group" "database" {
  count      = var.database_subnets_count > 0 && var.create_database_subnet_group ? 1 : 0
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.subnet_database[*].id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-db-subnet-group"
  })
}

# internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw-${var.region}"
  })
}

# default security group with no ingress/egress rules
# force to create explicit SGs
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  # No ingress/egress rules = fully locked down

  tags = merge(local.common_tags, {
    Name = "${var.environment}-default-sg-RESTRICTED"
  })
}

locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? var.public_subnets_count : 1)) : 0

  # For fck-nat, we just map route table IDs
  private_route_table_ids = { for i, rt in aws_route_table.private : "private-${i}" => rt.id }
}

# EIP for NAT Gateway
resource "aws_eip" "nat_eip" {
  count  = local.nat_gateway_count
  domain = "vpc"

  # ensure IGW exists before trying to allocate the EIP
  depends_on = [aws_internet_gateway.internet_gateway]
}

# NAT Gateway resource for public subnets
resource "aws_nat_gateway" "nat_gateway_public" {
  count             = local.nat_gateway_count
  allocation_id     = aws_eip.nat_eip[count.index].id
  subnet_id         = aws_subnet.subnet_public[count.index].id
  connectivity_type = var.connectivity_type

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-${data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]}"
  })

  depends_on = [aws_internet_gateway.internet_gateway]
}




# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    # route all to IGW
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

# public route table association
resource "aws_route_table_association" "public" {
  count          = var.public_subnets_count
  subnet_id      = aws_subnet.subnet_public[count.index].id
  route_table_id = aws_route_table.public.id
}

# private route table
resource "aws_route_table" "private" {
  count  = local.nat_gateway_count > 0 ? (local.nat_gateway_count == 1 ? 1 : var.private_subnets_count) : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = local.nat_gateway_count == 1 ? "${var.environment}-private-rt" : "${var.environment}-private-rt-${count.index + 1}"
  })
}

# NAT gateway resource for private subnets
resource "aws_route" "private_nat_gateway" {
  count                  = local.nat_gateway_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_public[count.index].id
}

# private route table association
resource "aws_route_table_association" "private" {
  count          = local.nat_gateway_count > 0 ? var.private_subnets_count : 0
  subnet_id      = aws_subnet.subnet_private[count.index].id
  route_table_id = aws_route_table.private[local.nat_gateway_count == 1 ? 0 : count.index].id
}

# NACLs for subnet-level rules
resource "aws_network_acl" "public" {
  count      = var.enable_custom_nacls ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.subnet_public[*].id

  # Allow HTTP/HTTPS inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-nacl"
  })
}

resource "aws_network_acl" "private" {
  count      = var.enable_custom_nacls ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.subnet_private[*].id

  # Allow inbound only from VPC CIDR
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow ephemeral port return traffic from internet (for NAT replies)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound (NAT gateway handles the routing)
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-nacl"
  })
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.nat_gateway_count > 0 ? aws_route_table.private[*].id : [aws_vpc.vpc.main_route_table_id]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-s3-endpoint"
  })
}

# Interface endpoints for EKS/ECS workloads
resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoint_services

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.subnet_private[*].id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.value}-endpoint"
  })
}

resource "aws_security_group" "vpc_endpoints" {
  count       = length(var.interface_endpoint_services) > 0 ? 1 : 0
  name_prefix = "${var.environment}-vpce-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpce-sg"
  })
}