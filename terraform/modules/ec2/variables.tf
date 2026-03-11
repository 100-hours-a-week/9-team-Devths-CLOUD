# ==============================================================================
# EC2 Module Variables
# ==============================================================================

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name to attach to the instance"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Assign a public IP to the instance"
  type        = bool
  default     = false
}

# ==============================================================================
# EBS Configuration
# ==============================================================================

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 80
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

# ==============================================================================
# Kubernetes Configuration
# ==============================================================================

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "pod_cidr" {
  description = "Pod CIDR"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.96.0.0/12"
}

variable "timezone" {
  description = "Timezone for the instance"
  type        = string
  default     = "Asia/Seoul"
}

variable "user_data_template_path" {
  description = "Path to the user data template file"
  type        = string
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
