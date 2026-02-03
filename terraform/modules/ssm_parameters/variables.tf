variable "environment_prefix" {
  description = "Environment prefix for parameter names (e.g., Dev, Stg, Prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
