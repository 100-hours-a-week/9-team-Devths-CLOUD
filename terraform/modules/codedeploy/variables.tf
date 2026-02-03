variable "app_name" {
  description = "CodeDeploy application name"
  type        = string
}

variable "deployment_group_name" {
  description = "Deployment group name"
  type        = string
}

variable "service_role_arn" {
  description = "IAM service role ARN for CodeDeploy"
  type        = string
}

variable "service_name" {
  description = "Service name (e.g., Frontend, Backend, AI)"
  type        = string
}

variable "ec2_tag_key" {
  description = "EC2 tag key to target instances"
  type        = string
  default     = "Name"
}

variable "ec2_tag_value" {
  description = "EC2 tag value to target instances"
  type        = string
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration"
  type        = string
  default     = "CodeDeployDefault.OneAtATime"
}

variable "auto_rollback_enabled" {
  description = "Enable auto rollback"
  type        = bool
  default     = false
}

variable "auto_rollback_events" {
  description = "Events that trigger auto rollback"
  type        = list(string)
  default     = ["DEPLOYMENT_FAILURE"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
