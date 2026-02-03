variable "project_name" {
  description = "Project name"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for SSM logs"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "cloudwatch_streaming_enabled" {
  description = "Enable CloudWatch streaming for sessions"
  type        = bool
  default     = true
}

variable "idle_session_timeout" {
  description = "Idle session timeout in minutes"
  type        = string
  default     = "20"
}

variable "max_session_duration" {
  description = "Maximum session duration in minutes"
  type        = string
  default     = "60"
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
