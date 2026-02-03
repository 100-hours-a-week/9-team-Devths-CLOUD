variable "environment_prefix" {
  description = "Environment prefix for parameter names (e.g., Dev, Stg, Prod)"
  type        = string
}

variable "be_parameter_values" {
  description = "Backend parameter values (optional, defaults to PLACEHOLDER)"
  type        = map(string)
  default     = {}
}

variable "ai_parameter_values" {
  description = "AI parameter values (optional, defaults to PLACEHOLDER)"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
