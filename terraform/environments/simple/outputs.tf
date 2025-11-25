output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = var.use_elastic_ip ? aws_eip.app[0].public_ip : aws_instance.app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = aws_instance.app.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if enabled)"
  value       = var.use_elastic_ip ? aws_eip.app[0].public_ip : null
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ~/.ssh/${var.project_name}-${var.environment}.pem ubuntu@${var.use_elastic_ip ? aws_eip.app[0].public_ip : aws_instance.app.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${var.use_elastic_ip ? aws_eip.app[0].public_ip : aws_instance.app.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.app.id
}
