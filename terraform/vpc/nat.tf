# nat gw
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.myvpc-public-1.id
  depends_on    = [aws_internet_gateway.myvpc-gw]
}

# VPC setup for NAT
resource "aws_route_table" "myvpc-private" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  # tags = {
  #   Name = "myvpc-private-1"
  # }
  tags = merge(
    local.tag,
    map("Name", "myvpc-private-route")
  )
}

# route associations private
resource "aws_route_table_association" "myvpc-private-1-a" {
  subnet_id      = aws_subnet.myvpc-private-1.id
  route_table_id = aws_route_table.myvpc-private.id
}

resource "aws_route_table_association" "myvpc-private-2-a" {
  subnet_id      = aws_subnet.myvpc-private-2.id
  route_table_id = aws_route_table.myvpc-private.id
}

resource "aws_route_table_association" "myvpc-private-3-a" {
  subnet_id      = aws_subnet.myvpc-private-3.id
  route_table_id = aws_route_table.myvpc-private.id
}

