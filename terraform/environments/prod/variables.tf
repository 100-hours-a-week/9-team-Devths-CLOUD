# 프로젝트 공통 변수
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# 환경 정의
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 변수
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# 퍼블릭 서브넷 CIDR
variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

# 프라이빗 서브넷 CIDR
variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# 가용영역
variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# EC2 변수
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

# SSH
variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "devths-prod"
}

# CodeDeploy 변수
variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration"
  type        = string
  default     = "CodeDeployDefault.OneAtATime"
}

# SSM 변수
variable "ssm_log_retention_days" {
  description = "SSM session log retention in days"
  type        = number
  default     = 30
}

# EIP 변수
variable "enable_eip" {
  description = "Enable Elastic IP for EC2 instance"
  type        = bool
  default     = true
}

# SSM Parameter Store 값
variable "be_parameter_values" {
  description = "Backend SSM parameter values (sensitive)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ai_parameter_values" {
  description = "AI SSM parameter values (sensitive)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
