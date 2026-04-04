
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



# EIP for NAT Gateway
resource "aws_eip" "nat_eip" {
  count  = local.nat_gw_count
  domain = "vpc"

  # ensure IGW exists before trying to allocate the EIP
  depends_on = [aws_internet_gateway.internet_gateway]
}

# NAT Gateway resource for public subnets
resource "aws_nat_gateway" "nat_gateway_public" {
  count             = local.nat_gw_count
  allocation_id     = aws_eip.nat_eip[count.index].id
  subnet_id         = aws_subnet.subnet_public[count.index].id
  connectivity_type = var.connectivity_type

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-${data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]}"
  })

  depends_on = [aws_internet_gateway.internet_gateway]
}


# ──────────────────────────────────────────────
# fck-nat Instance in ASG (cost-effective NAT with auto-recovery)
# ──────────────────────────────────────────────
# Instead of a bare EC2 instance, we use a Launch Template + ASG (min=max=1)
# so that AWS automatically replaces the instance if it becomes unhealthy.
# A dedicated ENI provides a stable network-interface ID for the private
# subnet route table — the ENI survives instance replacement.
# ──────────────────────────────────────────────

data "aws_ami" "fck_nat" {
  count       = local.use_nat_instance ? 1 : 0
  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-arm64-*"]
  }
}

resource "aws_security_group" "fck_nat" {
  count       = local.use_nat_instance ? 1 : 0
  name_prefix = "${var.environment}-fck-nat-"
  description = "Security group for fck-nat NAT instance"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow TCP for NAT"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  ingress {
    description = "Allow UDP for NAT"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-fck-nat-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Dedicated ENI — lives in the public subnet and persists across instance replacements.
# The private route table points at this ENI, so routing is unaffected during recovery.
resource "aws_network_interface" "fck_nat" {
  count             = local.nat_instance_count
  subnet_id         = aws_subnet.subnet_public[count.index].id
  security_groups   = [aws_security_group.fck_nat[0].id]
  source_dest_check = false
  description       = "Primary ENI for fck-nat instance (stable for route table)"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-fck-nat-eni-${data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]}"
  })
}

resource "aws_eip" "fck_nat" {
  count  = local.nat_instance_count
  domain = "vpc"

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_eip_association" "fck_nat" {
  count                = local.nat_instance_count
  network_interface_id = aws_network_interface.fck_nat[count.index].id
  allocation_id        = aws_eip.fck_nat[count.index].id
}

# IAM role for fck-nat instances (allows SSM and CloudWatch)
resource "aws_iam_role" "fck_nat" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.environment}-fck-nat-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.environment}-fck-nat-role"
  })
}

resource "aws_iam_role_policy_attachment" "fck_nat_ssm" {
  count      = local.use_nat_instance ? 1 : 0
  role       = aws_iam_role.fck_nat[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "fck_nat" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.environment}-fck-nat-profile"
  role  = aws_iam_role.fck_nat[0].name
}

# Launch Template — defines the fck-nat instance configuration
resource "aws_launch_template" "fck_nat" {
  count         = local.use_nat_instance ? 1 : 0
  name_prefix   = "${var.environment}-fck-nat-"
  image_id      = data.aws_ami.fck_nat[0].id
  instance_type = var.nat_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.fck_nat[0].name
  }

  # Attach the dedicated ENI as the primary network interface
  network_interfaces {
    device_index          = 0
    network_interface_id  = aws_network_interface.fck_nat[0].id
    delete_on_termination = false
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.environment}-fck-nat"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-fck-nat-lt"
  })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Auto Scaling Group — keeps exactly 1 fck-nat instance running.
# If the instance fails the EC2 health check, ASG terminates it and launches a replacement
# that re-attaches to the same ENI, preserving the EIP and route table entry.
resource "aws_autoscaling_group" "fck_nat" {
  count            = local.use_nat_instance ? 1 : 0
  name_prefix      = "${var.environment}-fck-nat-"
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
  # Place in the same AZ as the ENI
  availability_zones = [aws_subnet.subnet_public[0].availability_zone]

  health_check_type         = "EC2"
  health_check_grace_period = 120
  default_cooldown          = 60

  launch_template {
    id      = aws_launch_template.fck_nat[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-fck-nat"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

resource "aws_route" "public_internet_gateway" {
  count                  = var.enable_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway[0].id
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

# NAT Gateway route for private subnets
resource "aws_route" "private_nat_gateway" {
  count                  = local.nat_gw_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_public[count.index].id
}

# fck-nat instance route for private subnets (via stable ENI)
resource "aws_route" "private_nat_instance" {
  count                  = local.nat_instance_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.fck_nat[count.index].id
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

  # Allow all internal VPC traffic (needed so NAT instance can receive traffic)
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 0
    to_port    = 0
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

  # Allow UDP ephemeral ports for return traffic (required for QUIC)
  ingress {
    protocol   = "udp"
    rule_no    = 210
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

resource "aws_network_acl" "database" {
  count      = var.enable_custom_nacls && var.database_subnets_count > 0 ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.subnet_database[*].id

  # Allow inbound postgres from VPC CIDR
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 5432
    to_port    = 5432
  }

  # Allow ephemeral port return traffic (egress) to VPC CIDR
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-database-nacl"
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
