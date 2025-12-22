# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

# 3. Public subnet (ALB & NAT Gateway)
resource "aws_subnet" "public" {
  count             = length(var.public_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]
  
  map_public_ip_on_launch = true 

  tags = {
    Name = "${var.env}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# 4. Private subnet - App
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.env}-private-app-subnet-${count.index + 1}"
    Tier = "Private-App"
  }
}

# 5. Private subnet - Data (RDS)
resource "aws_subnet" "private_data" {
  count             = length(var.private_data_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.env}-private-data-subnet-${count.index + 1}"
    Tier = "Private-Data"
  }
}

# 6. NAT Gateway
resource "aws_eip" "nat" {
  count  = 1 
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id # In the public subnet

  tags = {
    Name = "${var.env}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 7. Routing tables

# A. Public table: All traffic to 0.0.0.0/0 goes to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

# B. Private App table: All traffic to 0.0.0.0/0 goes to the NAT Gateway
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.env}-private-app-rt"
  }
}

# C. Private Data table: Isolated (No route to internet)
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.main.id
  # No external routes, only local
  
  tags = {
    Name = "${var.env}-private-data-rt"
  }
}

# 8. Route Associations (Link Subnets with Tables)

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_subnets_cidr)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_data" {
  count          = length(var.private_data_subnets_cidr)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data.id
}