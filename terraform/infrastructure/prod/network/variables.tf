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
  description = "Infrastructure version"
  type        = string
  default     = "v2"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 변수
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

# 퍼블릭 서브넷 CIDR
variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["172.16.0.0/24", "172.16.1.0/24"]
}

# 프라이빗 서브넷 CIDR
variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.11.0/24"]
}

# 데이터베이스 서브넷 CIDR
variable "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["172.16.20.0/24", "172.16.21.0/24"]
}

# 가용영역
variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# NAT 설정
variable "nat_type" {
  description = "NAT type: 'gateway' (expensive but managed), 'instance' (cheap but self-managed), or 'none'"
  type        = string
  default     = "gateway"
}

variable "single_nat" {
  description = "Use a single NAT Gateway instead of one per AZ (cost optimization)"
  type        = bool
  default     = false # Production은 고가용성을 위해 각 AZ마다 NAT Gateway 사용
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
