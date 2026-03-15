# ==============================================================================
# Launch Template Variables
# ==============================================================================

variable "launch_template_name" {
  description = "Name of the launch template"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to instances"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "Provisioned IOPS for the root volume when using gp3"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Provisioned throughput for the root volume when using gp3"
  type        = number
  default     = 125
}

variable "custom_user_data_base64" {
  description = "Base64-encoded user data script"
  type        = string
  default     = ""
}

# ==============================================================================
# Auto Scaling Group Variables
# ==============================================================================

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "health_check_type" {
  description = "Type of health check (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG"
  type        = list(string)
}

variable "target_group_arns" {
  description = "List of target group ARNs for the ASG"
  type        = list(string)
  default     = []
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["OldestInstance"]
}

variable "default_cooldown" {
  description = "Default cooldown period in seconds"
  type        = number
  default     = 300
}

variable "wait_for_capacity_timeout" {
  description = "Maximum duration to wait for desired capacity"
  type        = string
  default     = "10m"
}

# ==============================================================================
# Environment & Tagging
# ==============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "infra_version" {
  description = "Infrastructure version"
  type        = string
}

variable "service_type" {
  description = "Service type (e.g., k8s-master, k8s-worker)"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Auto Scaling Policy Variables
# ==============================================================================

variable "enable_autoscaling" {
  description = "Enable auto scaling policies and CloudWatch alarms"
  type        = bool
  default     = false
}

variable "scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
}

variable "scale_up_cooldown" {
  description = "Cooldown period in seconds after scaling up"
  type        = number
  default     = 300
}

variable "scale_down_adjustment" {
  description = "Number of instances to remove when scaling down (negative number)"
  type        = number
  default     = -1
}

variable "scale_down_cooldown" {
  description = "Cooldown period in seconds after scaling down"
  type        = number
  default     = 300
}

# ==============================================================================
# CloudWatch Alarm Variables
# ==============================================================================

variable "high_cpu_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 80
}

variable "high_cpu_evaluation_periods" {
  description = "Number of periods to evaluate for high CPU alarm"
  type        = number
  default     = 2
}

variable "high_cpu_period" {
  description = "Period in seconds for high CPU alarm"
  type        = number
  default     = 300
}

variable "low_cpu_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 20
}

variable "low_cpu_evaluation_periods" {
  description = "Number of periods to evaluate for low CPU alarm"
  type        = number
  default     = 2
}

variable "low_cpu_period" {
  description = "Period in seconds for low CPU alarm"
  type        = number
  default     = 300
}
