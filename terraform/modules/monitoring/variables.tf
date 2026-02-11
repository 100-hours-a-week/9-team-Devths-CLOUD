# 프로젝트 전체에서 사용할 고유 이름
variable "project_name" {
  description = "Project name"
  type        = string
}


variable "instance_name" {
  description = "EC2 instance name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID for allowing traffic to Grafana"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "environment" {
  description = "Environment name (nonprod or prod)"
  type        = string

  validation {
    condition     = contains(["nonprod", "prod"], var.environment)
    error_message = "Environment must be 'nonprod' or 'prod'"
  }
}

variable "domain_name" {
  description = "Base domain name (e.g., devths.com)"
  type        = string
}

variable "monitoring_domain" {
  description = "Full monitoring domain (e.g., dev.monitoring.devths.com)"
  type        = string
}

variable "prometheus_retention" {
  description = "Prometheus data retention period (e.g., '30d', '90d')"
  type        = string
  default     = "30d"
}

variable "server_label" {
  description = "Server label for identification"
  type        = string
  default     = "모니터링 서버"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "aws_region" {
  description = "AWS region for EC2 service discovery"
  type        = string
  default     = "ap-northeast-2"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
