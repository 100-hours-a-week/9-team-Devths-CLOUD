# ============================================================================
# 도메인 명
# ============================================================================
variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
  default     = "devths.com"
}


# ============================================================================
# 지역
# ============================================================================
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
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
