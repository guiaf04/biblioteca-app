# Configuração principal do Terraform para infraestrutura da aplicação Biblioteca

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend para armazenar estado do Terraform (descomente e configure conforme necessário)
  # backend "s3" {
  #   bucket = "biblioteca-terraform-state"
  #   key    = "terraform.tfstate"
  #   region = "us-east-1"
  # }
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

# VPC
resource "aws_vpc" "biblioteca_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "biblioteca_igw" {
  vpc_id = aws_vpc.biblioteca_vpc.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnet pública
resource "aws_subnet" "biblioteca_public_subnet" {
  vpc_id                  = aws_vpc.biblioteca_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  }
}

# Route table para subnet pública
resource "aws_route_table" "biblioteca_public_rt" {
  vpc_id = aws_vpc.biblioteca_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.biblioteca_igw.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associação da route table com a subnet pública
resource "aws_route_table_association" "biblioteca_public_rta" {
  subnet_id      = aws_subnet.biblioteca_public_subnet.id
  route_table_id = aws_route_table.biblioteca_public_rt.id
}

# Security Group para a aplicação
resource "aws_security_group" "biblioteca_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = aws_vpc.biblioteca_vpc.id
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
# Agora espera o arquivo .pub gerado no pipeline (a partir do secret da chave privada)
resource "aws_key_pair" "biblioteca_key" {
  key_name   = "${var.project_name}-key"
  public_key = file("${path.module}/biblioteca-key.pub") # arquivo gerado no pipeline
  tags = {
    Name = "${var.project_name}-key-pair"
  }
}

# Remova a role IAM e o instance profile se não for necessário para sua aplicação.
# Comente ou remova os blocos abaixo se não precisar de permissões especiais para EC2 acessar ECR ou CloudWatch:
# resource "aws_iam_role" "biblioteca_ec2_role" { ... }
# resource "aws_iam_role_policy" "biblioteca_ecr_policy" { ... }
# resource "aws_iam_instance_profile" "biblioteca_profile" { ... }

# Na resource "aws_instance", remova a linha do instance profile:
resource "aws_instance" "biblioteca_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.biblioteca_key.key_name
  vpc_security_group_ids = [aws_security_group.biblioteca_sg.id]
  subnet_id              = aws_subnet.biblioteca_public_subnet.id

  user_data = local.user_data
  
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
  
  depends_on = [aws_internet_gateway.biblioteca_igw]
}

