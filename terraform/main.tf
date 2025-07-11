# Configuração principal do Terraform para infraestrutura da aplicação Biblioteca

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend S3 para armazenar o estado do Terraform de forma remota e segura.
  # IMPORTANTE: Substitua 'seu-bucket-de-estado-terraform-unico' pelo nome do bucket S3 que você criou.
  backend "s3" {
    bucket         = "biblioteca-app-terraform-tarc"
    key            = "production/terraform.tfstate" # O caminho do arquivo de estado dentro do bucket
    region         = "us-east-1"
    dynamodb_table = "biblioteca-terraform-locks" # O nome da sua tabela DynamoDB para state locking
  }
}

# Configuração do provider AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Biblioteca"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps"
    }
  }
}

# Data sources para obter informações da AWS
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Network Data Sources ---
# Instead of creating a new VPC on every run, we now look for a pre-existing one.
data "aws_vpc" "selected" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "selected" {
  vpc_id = data.aws_vpc.selected.id
  tags = {
    Name = var.public_subnet_name
  }
}

# Security Group para a aplicação
resource "aws_security_group" "biblioteca_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Security group for Biblioteca application"
  
  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }
  
  # HTTP (Frontend)
  ingress {
    description = "HTTP Frontend"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS (Frontend)
  ingress {
    description = "HTTPS Frontend"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Backend API
  ingress {
    description = "Backend API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Docker daemon (se necessário)
  ingress {
    description = "Docker daemon"
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  # Outbound - permitir todo tráfego
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-security-group"
  }
}

# Key Pair para acesso SSH
data "aws_key_pair" "biblioteca_key" {
  key_name = "${var.project_name}-key"
}

import {
  to = aws_ecr_repository.biblioteca_backend
  id = "biblioteca-backend"
}

import {
  to = aws_ecr_repository.biblioteca_frontend
  id = "biblioteca-frontend"
}

# ECR Repositories
resource "aws_ecr_repository" "biblioteca_backend" {
  name                 = "biblioteca-backend"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-backend-ecr"
  }
}

resource "aws_ecr_repository" "biblioteca_frontend" {
  name                 = "biblioteca-frontend"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-frontend-ecr"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "biblioteca_backend_policy" {
  repository = aws_ecr_repository.biblioteca_backend.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "biblioteca_frontend_policy" {
  repository = aws_ecr_repository.biblioteca_frontend.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Instância EC2
resource "aws_instance" "biblioteca_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.biblioteca_key.key_name
  vpc_security_group_ids = [aws_security_group.biblioteca_sg.id] # This SG is still created by TF
  subnet_id              = data.aws_subnet.selected.id
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
    
    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }
  
  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
    Application = "Biblioteca"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP
resource "aws_eip" "biblioteca_eip" {
  instance = aws_instance.biblioteca_server.id
  domain   = "vpc"
  
  tags = {
    Name = "${var.project_name}-eip"
  }
  
  # depends_on is no longer needed as the IGW is part of the pre-existing VPC
}
