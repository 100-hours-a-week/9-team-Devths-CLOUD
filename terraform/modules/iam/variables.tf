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
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSM parameter encryption"
  type        = string
}

variable "artifact_bucket_arn" {
  description = "S3 artifact bucket ARN for CodeDeploy"
  type        = string
}

variable "storage_bucket_arn" {
  description = "S3 storage bucket ARN for application data"
  type        = string
}

variable "ssm_log_bucket_arn" {
  description = "S3 bucket ARN for SSM Session Manager logs"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for SSM sessions"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
