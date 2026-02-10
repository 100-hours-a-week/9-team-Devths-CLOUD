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

variable "discord_webhook_url" {
  description = "Discord webhook URL for notifications"
  type        = string
  sensitive   = true
}

variable "discord_role_id" {
  description = "Discord role ID to mention (optional)"
  type        = string
  sensitive   = true
}

variable "log_group_name" {
  description = "CloudWatch Log Group name to query dangerous commands"
  type        = string
  default     = "SSMSessionMangerLogGroup"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
