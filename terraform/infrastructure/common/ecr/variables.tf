# 프로젝트 공통 변수
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# AWS 지역
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

# ECR 레포지토리 목록
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

# 공통 Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "devths"
    ManagedBy = "Terraform"
  }
}
