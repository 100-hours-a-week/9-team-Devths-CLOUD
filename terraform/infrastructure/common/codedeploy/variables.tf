# ============================================================================
# 공통
# ============================================================================
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}


# ============================================================================
# 프런트 엔드
# ============================================================================
variable "codedeploy_app_name_fe" {
  description = "CodeDeploy application name for Frontend"
  type        = string
  default     = "Devths-FE"
}

# ============================================================================
# 백엔드
# ============================================================================
variable "codedeploy_app_name_be" {
  description = "CodeDeploy application name for Backend"
  type        = string
  default     = "Devths-BE"
}


# ============================================================================
# 인공지능
# ============================================================================
variable "codedeploy_app_name_ai" {
  description = "CodeDeploy application name for AI"
  type        = string
  default     = "Devths-AI"
}

# ============================================================================
# 공통 태그
# ============================================================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}
