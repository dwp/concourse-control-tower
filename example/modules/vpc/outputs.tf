output "aws_vpc" {
  value = aws_vpc.main
}

output "aws_subnets_public" {
  value = aws_subnet.public
}

output "aws_subnets_private" {
  value = aws_subnet.private
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.main
}

output "aws_nat_gateway" {
  value = aws_nat_gateway.nat
}
