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
