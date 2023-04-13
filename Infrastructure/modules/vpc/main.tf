resource "aws_vpc" "workload" {
  cidr_block           = "10.0.0.0/${lookup(local.vpc_netmask, var.vpc_size)}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-${var.workload_name}-${var.environment}" }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.workload.id
  tags   = { Name = "igw-${var.workload_name}-${var.environment}" }
}

# PUBLIC SUBNETS
resource "aws_subnet" "frontend" {
  for_each          = local.vpc_sizes[var.vpc_size].frontend_subnets_cidrs
  vpc_id            = aws_vpc.workload.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "frontend-${each.value.az}" }
}

resource "aws_route_table" "frontend" {
  vpc_id = aws_vpc.workload.id
  # Default route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "frontend-rtb" }
}

resource "aws_route_table_association" "frontend" {
  for_each       = aws_subnet.frontend
  subnet_id      = each.value.id
  route_table_id = aws_route_table.frontend.id
}

# PRIVATE 
resource "aws_subnet" "application" {
  for_each          = local.vpc_sizes[var.vpc_size].application_subnets_cidrs
  vpc_id            = aws_vpc.workload.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "application-${each.value.az}" }
}

# NATGW
resource "aws_eip" "eip" {
  # The maximum number of addresses has been reached. (in eu-central-1) :(
  # for_each = aws_subnet.frontend
  vpc      = true
  tags          = { Name = "eip-${var.workload_name}-${var.environment}" }
}

resource "aws_nat_gateway" "nat" {
  # The maximum number of addresses has been reached. (in eu-central-1) :(
  # for_each = aws_subnet.frontend

  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.frontend["az-a"].id # Not resilient but this is POC
  tags          = { Name = "nat-${var.workload_name}-${var.environment}" }
}

resource "aws_route_table" "application" {
  # The maximum number of addresses has been reached. (in eu-central-1) :(
  # for_each = aws_subnet.application

  vpc_id = aws_vpc.workload.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "application-rtb-${var.workload_name}-${var.environment}" }
}

resource "aws_route_table_association" "application" {
  # The maximum number of addresses has been reached. (in eu-central-1) :(
  for_each = aws_subnet.application

  subnet_id      = each.value.id
  route_table_id = aws_route_table.application.id
}
