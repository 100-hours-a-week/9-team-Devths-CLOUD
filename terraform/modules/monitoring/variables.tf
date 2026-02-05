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

variable "target_dev_ip" {
  description = "Dev EC2 private IP for monitoring target (only for nonprod)"
  type        = string
  default     = ""
}

variable "target_staging_ip" {
  description = "Staging EC2 private IP for monitoring target (only for nonprod)"
  type        = string
  default     = ""
}

variable "target_prod_ip" {
  description = "Prod EC2 private IP for monitoring target (only for prod)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
