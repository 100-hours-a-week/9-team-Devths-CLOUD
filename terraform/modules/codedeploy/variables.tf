# CodeDeploy Application 이름(공유 스택에서 생성)
variable "app_name" {
  description = "CodeDeploy application name"
  type        = string
}

# 배포 그룹
variable "deployment_group_name" {
  description = "Deployment group name"
  type        = string
}

variable "service_role_arn" {
  description = "IAM service role ARN for CodeDeploy"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name to deploy to (optional)"
  type        = string
  default     = ""
}

variable "service_name" {
  description = "Service name (e.g., Frontend, Backend, Ai) - for tagging purposes"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stg, prod) - for tagging purposes"
  type        = string
}

variable "infra_version" {
  description = "Infrastructure version (e.g., v1, v2) - for tagging purposes"
  type        = string
  default     = "v2"
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration"
  type        = string
  default     = "CodeDeployDefault.OneAtATime"
}

# 자동 롤백 false
variable "auto_rollback_enabled" {
  description = "Enable auto rollback"
  type        = bool
  default     = false
}

# 자동 롤백 조건
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
