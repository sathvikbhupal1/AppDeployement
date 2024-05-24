
data "aws_instances" "private_instances" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.private_asg.name]
  }
}

output "private_instance_ips" {
  description = "Private IPv4 addresses of instances in the private subnet"
  value       = data.aws_instances.private_instances.private_ips
}

output "vpc_id" {
  value = aws_vpc.myvpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.PublicSubnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.PrivSubnet[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = [for nat_gw in aws_nat_gateway.nat_gw : nat_gw.id]
}

output "nat_gateway_eips" {
  description = "List of EIP Public IPs for NAT Gateways"
  value       = [for eip in aws_eip.nat_eip : eip.public_ip]
}

