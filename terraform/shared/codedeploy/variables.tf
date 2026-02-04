variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "codedeploy_app_name_fe" {
  description = "CodeDeploy application name for Frontend"
  type        = string
  default     = "Devths-V1-FE"
}

variable "codedeploy_app_name_be" {
  description = "CodeDeploy application name for Backend"
  type        = string
  default     = "Devths-V1-BE"
}

variable "codedeploy_app_name_ai" {
  description = "CodeDeploy application name for AI"
  type        = string
  default     = "Devths-V1-AI"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}
