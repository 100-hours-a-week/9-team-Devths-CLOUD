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
