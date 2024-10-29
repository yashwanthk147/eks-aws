resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "create-vpc-${var.env}"  
  }
}

#public subnets
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]

  tags = {
    Name = "create-${each.value["name"]}-${var.env}"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]

  tags = {
    Name = "create-${each.value["name"]}-${var.env}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "create-igw-${var.env}"
  }
}


# Create an Elastic IP (EIP) for the NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  for_each = var.public_subnets
  #depends_on = ["aws_internet_gateway.ocreate_igw-${var.ENV}"]
  tags = {
    Name = "create-${each.value["name"]}-${var.env}"
  }

} 


resource "aws_nat_gateway" "nat_gateway" {
  for_each = var.public_subnets
  allocation_id  = aws_eip.nat_gateway_eip[each.value["name"]].id
  subnet_id      = aws_subnet.public_subnets[each.value["name"]].id
  tags = {
    Name = "create-ngw-${each.value["name"]}-${var.env}"
  }
}


#Public routetable
resource "aws_route_table" "public-route-table" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "create-${each.value["name"]}-${var.env}"
  }
}

resource "aws_route_table_association" "public-association" {
  for_each = var.public_subnets
  subnet_id      = aws_subnet.public_subnets[each.value["name"]].id
  route_table_id = aws_route_table.public-route-table[each.value["name"]].id
}


#Public routetable
resource "aws_route_table" "private-route-table" {
  for_each = var.private_subnets
  vpc_id = aws_vpc.main.id  
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway["public-${split("-", each.value["name"])[1]}"].id
  }

  tags = {
    Name = "create-${each.value["name"]}-${var.env}"
  }
}


resource "aws_route_table_association" "private-association" {
  for_each = var.private_subnets
  subnet_id      = aws_subnet.private_subnets[each.value["name"]].id
  route_table_id = aws_route_table.private-route-table[each.value["name"]].id
}


output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private_subnets : subnet.id]  # Corrected output
}