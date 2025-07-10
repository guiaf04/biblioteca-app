# Variáveis do Terraform para infraestrutura da aplicação Biblioteca

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "biblioteca"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t3a.micro", "t3a.small", "t3a.medium", "t3a.large",
      "m5.large", "m5.xlarge", "m5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 8 and 100 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  default     = ""
}

variable "backend_image" {
  description = "Docker image for backend application"
  type        = string
  default     = "biblioteca-backend:latest"
}

variable "frontend_image" {
  description = "Docker image for frontend application"
  type        = string
  default     = "biblioteca-frontend:latest"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instance"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

variable "auto_scaling_enabled" {
  description = "Enable auto scaling"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 3
}

variable "desired_instances" {
  description = "Desired number of instances in auto scaling group"
  type        = number
  default     = 1
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
  
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be EC2 or ELB."
  }
}

variable "enable_ssl" {
  description = "Enable SSL/TLS"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of SSL certificate"
  type        = string
  default     = ""
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

