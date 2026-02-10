# ============================================================================
# Launch Template 설정
# ============================================================================

variable "launch_template_name" {
  description = "Launch Template name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

# ============================================================================
# Auto Scaling Group 설정
# ============================================================================

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of target group ARNs for ALB integration"
  type        = list(string)
  default     = []
}

# ============================================================================
# 환경 설정
# ============================================================================

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "v2"
}

variable "domain_name" {
  description = "Base domain name (e.g., devths.com)"
  type        = string
  default     = "devths.com"
}

variable "service_type" {
  description = "Service type to deploy (fe, be, ai, all)"
  type        = string
  default     = "all"
  validation {
    condition     = contains(["fe", "be", "ai", "all"], var.service_type)
    error_message = "service_type must be one of: fe, be, ai, all"
  }
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for fail2ban notifications"
  type        = string
  sensitive   = true
}

# ============================================================================
# 인스턴스 설정
# ============================================================================

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

# ============================================================================
# 태그
# ============================================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# AWS 설정
# ============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}
