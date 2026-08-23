output "aws_region" {
  description = "AWS Region used by this lab."
  value       = var.aws_region
}

output "availability_zone" {
  description = "Availability Zone selected for both subnets."
  value       = local.availability_zone
}

output "vpc_id" {
  description = "ID of the practice VPC."
  value       = aws_vpc.practice.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.practice.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}
