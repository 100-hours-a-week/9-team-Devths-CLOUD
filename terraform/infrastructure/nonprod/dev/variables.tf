# ============================================================================
# 프로젝트 공통
# ============================================================================
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# 환경 정의
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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

# EC2 변수
variable "fe_instance_type" {
  description = "Frontend EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "be_instance_type" {
  description = "Backend EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ai_instance_type" {
  description = "AI EC2 instance type"
  type        = string
  default     = "t3.micro"
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
  default     = "CodeDeployDefault.AllAtOnce"
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
  description = "RDS 데이터베이스명"
  type        = string
  sensitive   = true
}

variable "rds_db_username" {
  description = "RDS 유저명"
  type        = string
  sensitive   = true
}

variable "rds_db_password" {
  description = "RDS 비밀번호"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS 인스턴스 종류"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS 디스크 할당량"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS 최대 할당량"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "RDS 백업 보유날"
  type        = number
  default     = 7
}

# ============================================================================
# ASG 관련 변수
# ============================================================================
variable "asg_min_size" {
  description = "ASG 최소 개수"
  type        = number
  default     = 0
}

variable "asg_max_size" {
  description = "ASG 최대 개수"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "ASG 목표 개수"
  type        = number
  default     = 0
}

variable "asg_health_check_type" {
  description = "ASG 헬스체크 타입"
  type        = string
  default     = "ELB"
}

variable "asg_health_check_grace_period" {
  description = "ASG 헬스체크 시간"
  type        = number
  default     = 300
}

variable "asg_root_volume_size" {
  description = "ASG 기본 용량"
  type        = number
  default     = 30
}

variable "asg_root_volume_type" {
  description = "ASG root volume type"
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
    Environment = "dev"
    Version     = "v2"
    ManagedBy   = "Terraform"
  }
}
