output "id" {
  value = aws_vpc.myvpc.id
}

output "subnet-public-1-id" {
  value = aws_subnet.myvpc-public-1.id
}
