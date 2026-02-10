variable "aws_region" {
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
  default     = "prod"
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "devths.com"
}

variable "instance_type" {
  description = "EC2 instance type for monitoring server"
  type        = string
  default     = "t3.large"
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
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Devths"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Monitoring"
  }
}
