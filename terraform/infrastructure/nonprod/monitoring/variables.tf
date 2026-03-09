variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

# 인프라 버전
variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "v2"
}

variable "tf_state_bucket" {
  description = "State 저장을 위한 S3 bucket"
  type        = string
  default     =   "devths-state-terraform"
}

variable "tf_state_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "nonprod"
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "devths.com"
}

variable "instance_type" {
  description = "EC2 instance type for monitoring server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "root_volume_size" {
  description = "기본 저장 용량"
  type        = number
  default     = 50
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Project     = "Devths"
    Environment = "NonProd"
    ManagedBy   = "Terraform"
    Version     = "v2"
    Purpose     = "Monitoring"
  }
}
