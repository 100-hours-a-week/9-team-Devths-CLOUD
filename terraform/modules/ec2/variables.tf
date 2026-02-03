variable "instance_name" {
  description = "EC2 instance name"
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

variable "subnet_id" {
  description = "Subnet ID where EC2 will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for EC2"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

# AWS 지역
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

# EIP 활성화 여부
variable "enable_eip" {
  description = "Enable Elastic IP for the instance"
  type        = bool
  default     = true
}

# 공통 태그
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
