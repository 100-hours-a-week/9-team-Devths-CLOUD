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

variable "github_actions_user_name" {
  description = "GitHub Actions IAM user name"
  type        = string
  default     = "devths-github-actions"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    Project     = "Devths"
    ManagedBy   = "Terraform"
    Environment = "Shared"
  }
}
