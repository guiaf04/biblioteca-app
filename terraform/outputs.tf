# Outputs do Terraform para infraestrutura da aplicação Biblioteca

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.biblioteca_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.biblioteca_vpc.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.biblioteca_public_subnet.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.biblioteca_sg.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.biblioteca_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.biblioteca_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.biblioteca_server.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.biblioteca_server.public_dns
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = data.aws_key_pair.biblioteca_key.key_name
}

output "ecr_backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.biblioteca_backend.repository_url
}

output "ecr_frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.biblioteca_frontend.repository_url
}

output "ecr_backend_repository_arn" {
  description = "ARN of the backend ECR repository"
  value       = aws_ecr_repository.biblioteca_backend.arn
}

output "ecr_frontend_repository_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.biblioteca_frontend.arn
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.biblioteca_eip.public_ip}"
}

output "backend_api_url" {
  description = "URL to access the backend API"
  value       = "http://${aws_eip.biblioteca_eip.public_ip}:8080/api"
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${data.aws_key_pair.biblioteca_key.key_name}.pem ubuntu@${aws_eip.biblioteca_eip.public_ip}"
}

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.biblioteca_backend.repository_url)[0]}"
}

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    vpc_id                    = aws_vpc.biblioteca_vpc.id
    instance_id               = aws_instance.biblioteca_server.id
    public_ip                 = aws_eip.biblioteca_eip.public_ip
    security_group_id         = aws_security_group.biblioteca_sg.id
    backend_ecr_repository    = aws_ecr_repository.biblioteca_backend.repository_url
    frontend_ecr_repository   = aws_ecr_repository.biblioteca_frontend.repository_url
    application_url           = "http://${aws_eip.biblioteca_eip.public_ip}"
    backend_api_url           = "http://${aws_eip.biblioteca_eip.public_ip}:8080/api"
    ssh_command               = "ssh -i ~/.ssh/${data.aws_key_pair.biblioteca_key.key_name}.pem ubuntu@${aws_eip.biblioteca_eip.public_ip}"
  }
}

