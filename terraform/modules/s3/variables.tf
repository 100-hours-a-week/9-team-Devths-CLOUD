# 버킷명
variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

# 버킷 설명
variable "purpose" {
  description = "Purpose of the S3 bucket"
  type        = string
  default     = ""
}

# S3 버저닝
variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

# S3 라이프사이클 설정
variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    id               = string
    status           = string
    noncurrent_days  = optional(number)
    expiration_days  = optional(number)
  }))
  default = null
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# CORS 설정
variable "cors_rules" {
  description = "CORS rules for the bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = null
}

# 퍼블릭 액세스 차단 설정
variable "block_public_access" {
  description = "Enable public access blocking"
  type        = bool
  default     = true
}

# 퍼블릭 읽기 정책 활성화
variable "enable_public_read" {
  description = "Enable public read access to all objects in the bucket"
  type        = bool
  default     = false
}
