# ============================================================================
# 프로젝트 공통
# ============================================================================

# 프로젝트 전체에서 사용할 고유 이름
variable "project_name" {
  description = "Project name"
  type        = string
}

# 배포 대상 환경
variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
}

variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "V2"
}

# ============================================================================
# 네트워크 대역
# ============================================================================

# VPC의 전체 네트워크 대역 설정
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

# 외부 통신이 가능한 퍼블릭 서브넷들의 CIDR 리스트
variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

# 내부 통신 전용 프라이빗 서브넷들의 CIDR 리스트
variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

# 데이터베이스 전용 서브넷들의 CIDR 리스트 (3-tier 아키텍처)
variable "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

# 리소스가 분산 배치될 가용 영역(AZ) 목록
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# SSH 접속을 허용할 IP 대역 (보안을 위해 필요한 경우에만 입력)
variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH (optional)"
  type        = list(string)
  default     = []
}

# ============================================================================
# NAT 관련
# ============================================================================

# NAT 설정 - Gateway 또는 Instance 선택
variable "nat_type" {
  description = "NAT type: 'gateway' (expensive but managed), 'instance' (cheap but self-managed), or 'none'"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["gateway", "instance", "none"], var.nat_type)
    error_message = "nat_type must be 'gateway', 'instance', or 'none'."
  }
}

# NAT Gateway/Instance를 각 AZ마다 생성할지 여부 (고가용성)
variable "single_nat" {
  description = "Use a single NAT (Gateway or Instance) instead of one per AZ (cost optimization for nonprod)"
  type        = bool
  default     = true
}

# NAT Instance 인스턴스 타입
variable "nat_instance_type" {
  description = "Instance type for NAT instance (t3.nano recommended for nonprod)"
  type        = string
  default     = "t3.nano"
}

# NAT Instance SSH 키
variable "nat_key_name" {
  description = "EC2 Key Pair name for NAT instance SSH access"
  type        = string
  default     = null
}

# NAT Instance IAM 인스턴스 프로파일
variable "nat_iam_instance_profile_name" {
  description = "IAM instance profile name for NAT instance (for SSM and CloudWatch)"
  type        = string
  default     = null
}

# 하위 호환성을 위한 변수들 (deprecated)
variable "enable_nat_gateway" {
  description = "[DEPRECATED] Use nat_type='gateway' instead"
  type        = bool
  default     = null
}

variable "single_nat_gateway" {
  description = "[DEPRECATED] Use single_nat instead"
  type        = bool
  default     = null
}

# 기본 규칙 외에 보안 그룹에 추가로 정의할 인입 규칙들
variable "additional_ingress_rules" {
  description = "Additional ingress rules for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# 공통 태그
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}