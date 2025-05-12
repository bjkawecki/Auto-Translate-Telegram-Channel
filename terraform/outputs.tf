output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID der VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "ID des öffentlichen Subnetzes"
}


output "internet_gateway_id" {
  value       = aws_internet_gateway.igw.id
  description = "ID des Internet Gateways"
}


output "public_instance_id" {
  value       = aws_instance.public.id
  description = "ID der öffentlichen EC2-Instanz"
}


output "security_group_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID der EC2 Security Group"
}
