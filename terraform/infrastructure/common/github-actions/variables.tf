# ============================================================================
# 공통 변수
# ============================================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================================================
# 계정 ID
# ============================================================================
variable "account_id" {
  description = "유저 ID"
  type        = string
  default     = "174678835309"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "devths"
}

# ============================================================================
# 이름
# ============================================================================
variable "github_actions_user_name" {
  description = "GitHub Actions IAM user name"
  type        = string
  default     = "devths-github-actions"
}


# ============================================================================
# 공통 태그
# ============================================================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Devths"
    ManagedBy   = "Terraform"
    Environment = "Shared"
  }
}
