# 프로젝트 공통 변수
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 변수
variable "vpc_cidr" {
  description = "VPC CIDR block for 3-tier architecture"
  type        = string
  default     = "192.168.0.0/16"
}

# 퍼블릭 서브넷 CIDR (Web tier: 192.168.1.0 ~ 2.0)
variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]
}

# 프라이빗 서브넷 CIDR (App tier: 192.168.10.0 ~ 11.0)
variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.10.0/24", "192.168.11.0/24"]
}

# 데이터베이스 서브넷 CIDR (Data tier: 192.168.20.0 ~ 21.0)
variable "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.20.0/24", "192.168.21.0/24"]
}

# 가용영역
variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# NAT 설정 (Instance 사용 - 비용 절감)
variable "nat_type" {
  description = "NAT type: 'gateway' (~$33/mo), 'instance' (~$3/mo), or 'none'"
  type        = string
  default     = "instance" # nonprod는 비용 절감을 위해 instance 사용
}

variable "single_nat" {
  description = "Use a single NAT instead of one per AZ (cost optimization for nonprod)"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance (t3.nano is sufficient for nonprod)"
  type        = string
  default     = "t3.nano"
}

variable "certificate_arn" {
  description = "Certificate Manager"
  type        = string
  default     = "arn:aws:acm:ap-northeast-2:174678835309:certificate/7ab71742-f7e2-44a8-979c-50b4287ba5e5"
}

# 공통 Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project      = "devths"
    Environment  = "non-prod"
    ManagedBy    = "Terraform"
    Architecture = "3-tier"
  }
}
