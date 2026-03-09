# ============================================================================
# 환경 설정
# ============================================================================

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "v2"
}

variable "service_type" {
  description = "Service type to deploy (fe, be, ai, monitor, all)"
  type        = string
  default     = "all"
  validation {
    condition     = contains(["fe", "be", "ai", "mock", "monitor", "all"], var.service_type)
    error_message = "service_type must be one of: fe, be, ai, mock, monitor, all"
  }
}


# ============================================================================
# 시작 템플릿 설정
# ============================================================================

variable "launch_template_name" {
  description = "시작 템플릿 name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

# ============================================================================
# Auto Scaling Group 설정
# ============================================================================

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "ELB"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of target group ARNs for ALB integration"
  type        = list(string)
  default     = []
}

# ============================================================================
# 인스턴스 설정
# ============================================================================

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

# ============================================================================
# 태그
# ============================================================================

variable "common_tags" {
  description = "Common tags for resources and ASG-propagated instance tags"
  type        = map(string)
  default     = {}
}

# ============================================================================
# AWS 설정
# ============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "custom_user_data_base64" {
  description = "Base64-encoded custom user data. If null, module default user data is used."
  type        = string
  default     = null
}

# ============================================================================
# Auto Scaling Policy 설정
# ============================================================================

variable "enable_autoscaling" {
  description = "Enable CPU-based auto scaling"
  type        = bool
  default     = true
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for target tracking scaling policy"
  type        = number
  default     = 60
}

variable "scale_out_cpu_threshold" {
  description = "CPU threshold percentage for scaling out (adding instances)"
  type        = number
  default     = 70
}

variable "scale_in_cpu_threshold" {
  description = "CPU threshold percentage for scaling in (removing instances)"
  type        = number
  default     = 30
}

# ============================================================================
# Scheduled Scaling 설정
# ============================================================================

variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling actions"
  type        = bool
  default     = false
}

variable "schedule_scale_down_time" {
  description = "Cron expression for scaling down (UTC timezone). Example: '0 13 * * *' for daily at 13:00 UTC"
  type        = string
  default     = ""
}

variable "schedule_scale_down_min_size" {
  description = "Minimum size during scale down schedule"
  type        = number
  default     = 0
}

variable "schedule_scale_down_max_size" {
  description = "Maximum size during scale down schedule"
  type        = number
  default     = 0
}

variable "schedule_scale_down_desired" {
  description = "Desired capacity during scale down schedule"
  type        = number
  default     = 0
}

variable "schedule_scale_up_time" {
  description = "Cron expression for scaling up (UTC timezone). Example: '0 4 * * *' for daily at 04:00 UTC"
  type        = string
  default     = ""
}

variable "schedule_scale_up_min_size" {
  description = "Minimum size during scale up schedule"
  type        = number
  default     = 1
}

variable "schedule_scale_up_max_size" {
  description = "Maximum size during scale up schedule"
  type        = number
  default     = 3
}

variable "schedule_scale_up_desired" {
  description = "Desired capacity during scale up schedule"
  type        = number
  default     = 1
}
