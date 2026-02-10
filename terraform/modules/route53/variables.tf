variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
}

variable "subdomain_prefix" {
  description = "Subdomain prefix for environment (e.g., 'dev', 'stg'). Leave empty for root domain."
  type        = string
  default     = ""
}

variable "public_ip" {
  description = "Public IP address to point records to (EIP if enabled, otherwise instance public IP)"
  type        = string
  default     = null
}

variable "use_alb_alias" {
  description = "Whether to use ALB alias record instead of A record with IP"
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "ALB DNS name (required when use_alb_alias is true)"
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID (required when use_alb_alias is true)"
  type        = string
  default     = null
}

variable "create_root_record" {
  description = "Whether to create root/base domain record"
  type        = bool
  default     = true
}

variable "create_www_record" {
  description = "Whether to create www subdomain record"
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

variable "ttl" {
  description = "TTL for DNS records"
  type        = number
  default     = 300
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
