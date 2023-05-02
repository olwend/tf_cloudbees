output "vpc_id" {
  value = aws_vpc.g2_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.g2_vpc.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.g2_public_subnet.id
}

output "sg_id" {
  value = aws_security_group.g2_sg.id
}