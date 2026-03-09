# ============================================================================
# 공통
# ============================================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# ============================================================================
# S3 버킷명
# ============================================================================
variable "bucket_name" {
  description = "S3 bucket name for SSM logs"
  type        = string
  default     = "devths-log-ssm"
}

# ============================================================================
# 클라우드 워치
# ============================================================================
variable "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for SSM sessions"
  type        = string
  default     = "SSMSessionMangerLogGroup"
}

variable "ssm_document_name" {
  description = "SSM Document name"
  type        = string
  default     = "SSM-SessionManagerRunShell"
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

# ============================================================================
# SNS 알림
# ============================================================================
variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch Alarm notifications (optional)"
  type        = string
  default     = ""
}

# ============================================================================
# 공통 태그
# ============================================================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "devths"
    Environment = "shared"
    ManagedBy = "Terraform"
  }
}
