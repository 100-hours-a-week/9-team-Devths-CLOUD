variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "purpose" {
  description = "Purpose of the S3 bucket"
  type        = string
  default     = ""
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

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
