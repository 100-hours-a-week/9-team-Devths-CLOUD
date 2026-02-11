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

variable "create_grafana_record" {
  description = "Whether to create grafana subdomain record"
  type        = bool
  default     = false
}

variable "create_prometheus_record" {
  description = "Whether to create prometheus subdomain record"
  type        = bool
  default     = false
}
