resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_name.id
  }
  tags = {
    Name = "${local.env}-private-rt"
  }

}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.env}-public-rt"
  }
}

#PRIVATE ROUTE TABLE ASSOCIATIONS
#Associate Private Subnet -1 with Private Route Table
resource "aws_route_table_association" "private_zone_1_association" {
  subnet_id      = aws_subnet.private_zone_1.id
  route_table_id = aws_route_table.private_route_table.id
}

#Associate Private Subnet -2 with Private Route Table
resource "aws_route_table_association" "private_zone_2_association" {
  subnet_id      = aws_subnet.private_zone_2.id
  route_table_id = aws_route_table.private_route_table.id
}

#PUBLIC ROUTE TABLE ASSOCIATIONS
#Associate Public Subnet -1 with Public Route Table
resource "aws_route_table_association" "public_zone_1_association" {
  subnet_id      = aws_subnet.public_zone_1.id
  route_table_id = aws_route_table.public_route_table.id
}

#Associate Public Subnet -2 with Public Route Table
resource "aws_route_table_association" "public_zone_2_association" {
  subnet_id      = aws_subnet.public_zone_2.id
  route_table_id = aws_route_table.public_route_table.id
}
