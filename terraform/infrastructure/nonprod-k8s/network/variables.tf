# ============================================================================
# 프로젝트 공통
# ============================================================================

# 프로젝트 명
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# 인프라 버전
variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "v3"
}

# 환경
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "nonprod"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================================================
# 버킷
# ============================================================================

variable "tf_state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "devths-state-terraform"
}

variable "tf_state_region" {
  description = "AWS region where Terraform remote state bucket exists"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================================================
# VPC
# ============================================================================

# VPC 변수
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

# ============================================================================
# 서브넷
# ============================================================================

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

# ============================================================================
# NAT
# ============================================================================
variable "nat_type" {
  description = "NAT type"
  type        = string
  default     = "instance" # nonprod-k8s는 기본적으로 NAT 없이 구성
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

# ============================================================================
# 쿠버네티스 보안그룹
# ============================================================================

variable "k8s_api_server_allowed_cidrs" {
  description = "Additional CIDRs that may reach the Kubernetes API server on port 6443"
  type        = list(string)
  default     = []
}

variable "k8s_ingress_allowed_cidrs" {
  description = "CIDRs allowed to reach ports 80 and 443 on Kubernetes nodes"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "k8s_nodeport_allowed_cidrs" {
  description = "CIDRs allowed to reach the Kubernetes NodePort range"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "calico_overlay_udp_port" {
  description = "UDP port used for Calico VXLAN overlay traffic; Calico VXLAN uses 4789"
  type        = number
  default     = 4789
}

# ============================================================================
# 공통 태그
# ============================================================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project      = "devths"
    Environment  = "nonprod"
    ManagedBy    = "Terraform"
    Version      = "v3"
    Architecture = "3-tier"
  }
}
