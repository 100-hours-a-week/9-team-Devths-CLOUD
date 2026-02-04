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
  default     = "stg"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 변수 (공유 VPC 사용으로 제거됨)
# VPC 설정은 terraform/shared/vpc-nonprod 에서 관리

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
  default     = "devths-non-prod"
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
  default     = 7
}

# EIP 변수
variable "enable_eip" {
  description = "Enable Elastic IP for EC2 instance"
  type        = bool
  default     = false
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

# Discord Webhook URL (fail2ban 알림용)
variable "discord_webhook_url" {
  description = "Discord webhook URL for fail2ban security alerts"
  type        = string
  sensitive   = true
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
