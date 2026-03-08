variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
}

variable "subdomain_prefix" {
  description = "Subdomain prefix for environment (e.g., 'dev', 'stg'). Leave empty for root domain."
  type        = string
  default     = ""
}

# ========================================
# ALB 관련 변수 (애플리케이션 서비스)
# ========================================

variable "alb_dns_name" {
  description = "ALB DNS name for application services"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for application services"
  type        = string
}

# ========================================
# 레코드 생성 플래그
# ========================================

variable "create_root_record" {
  description = "Whether to create root/base domain record"
  type        = bool
  default     = true
}

variable "create_www_record" {
  description = "Whether to create www subdomain record (prod only)"
  type        = bool
  default     = true
}

variable "create_api_record" {
  description = "Whether to create api subdomain record"
  type        = bool
  default     = true
}

variable "create_ai_record" {
  description = "Whether to create ai subdomain record"
  type        = bool
  default     = true
}

variable "create_monitoring_record" {
  description = "Whether to create monitoring subdomain record"
  type        = bool
  default     = false
}

# ========================================
# 가중치 기반 라우팅 변수 (V1/V2 병행 운영)
# ========================================

variable "enable_weighted_routing" {
  description = "Enable weighted routing for gradual migration from V1 to V2"
  type        = bool
  default     = false
}

variable "v1_instance_ip" {
  description = "V1 EC2 instance IP for weighted routing"
  type        = string
  default     = ""
}

variable "v1_weight" {
  description = "Weight for V1 instance (0-255)"
  type        = number
  default     = 50
}

variable "v2_weight" {
  description = "Weight for V2 ALB (0-255)"
  type        = number
  default     = 50
}

variable "create_v1_weighted_records" {
  description = "Create V1 weighted records. Keep false until legacy non-weighted records are fully migrated."
  type        = bool
  default     = false
}

# ========================================
# 헬스 체크 변수
# ========================================

variable "evaluate_target_health" {
  description = "Evaluate ALB target health for Route53 health checks. Set to false for environments with scheduled scaling to 0 instances."
  type        = bool
  default     = false
}
