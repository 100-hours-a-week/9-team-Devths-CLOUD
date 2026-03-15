# ============================================================================
# 공통 변수
# ============================================================================

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================================================
# 목록
# ============================================================================
variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = set(string)
  default = [
    "devths/ai-dev",
    "devths/ai-stg",
    "devths/ai-prod",
    "devths/be-dev",
    "devths/be-stg",
    "devths/be-prod",
    "devths/fe-dev",
    "devths/fe-stg",
    "devths/fe-prod"
  ]
}

# ============================================================================
# 공통 태그
# ============================================================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "devths"
    ManagedBy = "Terraform"
  }
}
