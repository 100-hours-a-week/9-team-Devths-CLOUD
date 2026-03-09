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

# 인프라 버전
variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "v2"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "tf_state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     =   "devths-state-terraform"
}

variable "tf_state_region" {
  description = "AWS region where Terraform remote state bucket exists"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 변수 (공유 VPC 사용으로 제거됨)
# VPC 설정은 terraform/shared/vpc-nonprod 에서 관리

# EC2 변수
variable "fe_instance_type" {
  description = "Frontend EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "be_instance_type" {
  description = "Backend EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ai_instance_type" {
  description = "AI EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "mock_instance_type" {
  description = "Mock server EC2 instance type"
  type        = string
  default     = "t3.small"
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

# ============================================================================
# RDS
# ============================================================================
variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  sensitive   = true
}

variable "rds_db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "rds_db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

# ============================================================================
# ASG 관련 변수
# ============================================================================
variable "asg_min_size" {
  description = "ASG minimum size for FE/BE/AI"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "ASG maximum size for FE/BE/AI"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity for FE/BE/AI"
  type        = number
  default     = 1
}

variable "mock_asg_min_size" {
  description = "ASG minimum size for Mock"
  type        = number
  default     = 1
}

variable "mock_asg_max_size" {
  description = "ASG maximum size for Mock"
  type        = number
  default     = 1
}

variable "mock_asg_desired_capacity" {
  description = "ASG desired capacity for Mock"
  type        = number
  default     = 1
}

variable "asg_health_check_type" {
  description = "ASG health check type (EC2 or ELB)"
  type        = string
  default     = "ELB"
}

variable "asg_health_check_grace_period" {
  description = "ASG health check grace period in seconds"
  type        = number
  default     = 300
}

variable "asg_root_volume_size" {
  description = "ASG root volume size in GB"
  type        = number
  default     = 30
}

variable "asg_root_volume_type" {
  description = "ASG root volume type"
  type        = string
  default     = "gp3"
}

variable "mock_root_volume_size" {
  description = "Mock ASG root volume size in GB"
  type        = number
  default     = 20
}

variable "mock_root_volume_type" {
  description = "Mock ASG root volume type"
  type        = string
  default     = "gp3"
}

# ============================================================================
# 공통 태그
# ============================================================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "staging"
    Version     = "v2"
    ManagedBy   = "Terraform"
  }
}
