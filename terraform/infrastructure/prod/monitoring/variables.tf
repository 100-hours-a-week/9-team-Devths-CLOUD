# ============================================================================
# 프로젝트 공통
# ============================================================================
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

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

variable "tf_state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
}

variable "tf_state_region" {
  description = "AWS region where Terraform remote state bucket exists"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "devths.com"
}

variable "instance_type" {
  description = "EC2 instance type for monitoring server"
  type        = string
  default     = "t3.small"
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

variable "alertmanager_discord_webhook_nonprod" {
  description = "Discord webhook URL for nonprod alert routing (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_discord_webhook_prod" {
  description = "Discord webhook URL for prod alert routing (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tempo_s3_bucket_name" {
  description = "Tempo trace storage S3 bucket name (optional)"
  type        = string
  default     = ""
}

variable "loki_s3_bucket_name" {
  description = "Loki log storage S3 bucket name (optional)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

# 공통 태그
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Devths"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Version     = "v2"
    Purpose     = "Monitoring"
  }
}
