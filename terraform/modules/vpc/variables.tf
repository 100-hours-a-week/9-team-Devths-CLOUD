# 프로젝트 전체에서 사용할 고유 이름
variable "project_name" {
  description = "Project name"
  type        = string
}

# 배포 대상 환경 (prod, staging, dev 등으로 구분하여 정책 제어)
variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
}

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

# 모든 리소스에 공통적으로 적용할 관리용 태그 (Cost Center, Owner 등)
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}