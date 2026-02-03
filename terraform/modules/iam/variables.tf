variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "environment_prefix" {
  description = "Environment prefix for SSM parameters (Dev, Stg, Prod)"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSM parameter encryption"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
