
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.subnet_public[*].id
}

output "private_subnets" {
  value = aws_subnet.subnet_private[*].id
}

output "public_rt" {
  value = aws_route_table.public.id
}

output "private_rt" {
  value = aws_route_table.private[*].id
}

output "nat_gateway_public" {
  value = aws_nat_gateway.nat_gateway_public[*].id
}