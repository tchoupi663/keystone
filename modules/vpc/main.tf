
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name        = "${var.environment}-vpc-${var.region}"
    Environment = var.environment
    Region      = var.region
  }
}

resource "aws_subnet" "subnet_public" {
  count                   = var.public_subnets_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet_private" {
  count  = var.private_subnets_count
  vpc_id = aws_vpc.vpc.id

  # we add 8 bits to the VPC CIDR block for the subnet addresses
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index + var.public_subnets_count)

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Region      = var.region
  }
}

locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? var.public_subnets_count : 1)) : 0
}

resource "aws_eip" "nat_eip" {
  count  = local.nat_gateway_count
  domain = "vpc"

  # ensure IGW exists before trying to allocate the EIP
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway_public" {
  count             = local.nat_gateway_count
  allocation_id     = aws_eip.nat_eip[count.index].id
  subnet_id         = aws_subnet.subnet_public[count.index].id
  connectivity_type = var.connectivity_type

  tags = {
    Name        = "${var.environment}-nat-gateway-public-${count.index + 1}"
    Environment = var.environment
    Region      = var.region
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway[0].id
  }

  tags = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = var.public_subnets_count
  subnet_id      = aws_subnet.subnet_public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = local.nat_gateway_count > 0 ? local.nat_gateway_count : 1
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.environment}-private-rt-${count.index + 1}" }
}

resource "aws_route" "private_nat_gateway" {
  count                  = local.nat_gateway_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = var.private_subnets_count
  subnet_id      = aws_subnet.subnet_private[count.index].id
  route_table_id = aws_route_table.private[local.nat_gateway_count == 1 ? 0 : count.index].id
}