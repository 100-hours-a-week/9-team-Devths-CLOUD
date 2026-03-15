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
}

variable "tf_state_region" {
  description = "AWS region where Terraform remote state bucket exists"
  type        = string
  default     = "ap-northeast-2"
}

# EC2 인스턴스 타입 변수 (ASG용)
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
  default     = "t3.small"
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

# RDS 변수
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
  default     = "db.t3.small"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage for autoscaling in GB"
  type        = number
  default     = 200
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 30
}

# ASG 변수
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
  default     = 2
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

# Route53 가중치 라우팅 변수
variable "route53_enable_weighted_routing" {
  description = "Enable weighted routing between V1 EC2 and V2 ALB"
  type        = bool
  default     = true
}

variable "route53_v1_instance_ip" {
  description = "V1 EC2 public IP used in weighted routing"
  type        = string
  default     = "52.79.193.215"
}

variable "route53_v1_weight" {
  description = "Route53 weight for V1 EC2 (0-255)"
  type        = number
  default     = 255
}

variable "route53_v2_weight" {
  description = "Route53 weight for V2 ALB (0-255)"
  type        = number
  default     = 0
}

variable "route53_create_v1_weighted_records" {
  description = "Create V1 weighted records (enable only after deleting legacy non-weighted records)"
  type        = bool
  default     = false
}

variable "route53_evaluate_target_health" {
  description = "Evaluate ALB target health for Route53 alias records"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "production"
    Version     = "v2"
    ManagedBy   = "Terraform"
  }
}
