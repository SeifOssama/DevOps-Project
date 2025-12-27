# === VPC Creation === #

resource "aws_vpc" "YAKOUT-VPC" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "SEIF-VPC"
  }
}


# === Public Subnets Creation === #

resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.YAKOUT-VPC.id
  cidr_block              = var.public-subnet1_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet1"
  }
}



# === Internet Gateway Creation === #

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.YAKOUT-VPC.id
  tags = {
    Name = "SEIF-IGW"
  }
}


# === Public Routing Table Creation === #

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.YAKOUT-VPC.id
  tags = {
    Name = "PublicRT"
  }
}

resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-subnet1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public_rt.id
}