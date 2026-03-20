# ============================================================================
# Project
# ============================================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

variable "environment" {
  description = "Environment name used for resource naming"
  type        = string
  default     = "nonprod"
}

variable "infra_version" {
  description = "Infrastructure version"
  type        = string
  default     = "v3"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "tf_state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "devths-state-terraform"
}

variable "tf_state_region" {
  description = "AWS region where Terraform remote state bucket exists"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================================================
# Cluster
# ============================================================================

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "Override name for the control-plane instance"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes minor version stream from pkgs.k8s.io (for example 1.32)"
  type        = string
  default     = "1.32"
}

variable "pod_cidr" {
  description = "Pod CIDR used by kubeadm init and the CNI"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Service CIDR used by kubeadm init"
  type        = string
  default     = "10.96.0.0/12"
}

# ============================================================================
# EC2
# ============================================================================

variable "worker_instance_type" {
  description = "EC2 instance type for the Kubernetes worker nodes"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "devths-non-prod"
}

variable "private_subnet_index" {
  description = "Index of the private subnet from nonprod-k8s/network remote state"
  type        = number
  default     = 0
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

variable "timezone" {
  description = "Timezone configured on the control-plane node"
  type        = string
  default     = "Asia/Seoul"
}

# ============================================================================
# Security
# ============================================================================

variable "api_server_allowed_cidrs" {
  description = "Additional CIDRs that may reach the Kubernetes API server on port 6443"
  type        = list(string)
  default     = []
}

# ============================================================================
# 워커노드 ASG
# ============================================================================

variable "worker_asg_min_size" {
  description = "Minimum number of K8s worker instances in ASG"
  type        = number
  default     = 1
}

variable "worker_asg_max_size" {
  description = "Maximum number of K8s worker instances in ASG"
  type        = number
  default     = 6
}

variable "worker_asg_desired_capacity" {
  description = "Desired number of K8s worker instances in ASG"
  type        = number
  default     = 2
}

variable "enable_worker_autoscaling" {
  description = "Enable auto scaling for K8s worker ASG"
  type        = bool
  default     = true
}

# ============================================================================
# ASG (Auto Scaling Group) - Common
# ============================================================================

variable "asg_health_check_type" {
  description = "ASG health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "asg_health_check_grace_period" {
  description = "ASG health check grace period in seconds"
  type        = number
  default     = 600
}

# ============================================================================
# Monitoring EC2
# ============================================================================

variable "monitoring_instance_type" {
  description = "EC2 instance type for the monitoring server"
  type        = string
  default     = "t3.medium"
}

variable "domain_name" {
  description = "Base domain name (e.g., devths.com)"
  type        = string
  default     = "devths.com"
}

variable "monitoring_domain" {
  description = "Full monitoring domain for Grafana (e.g., k8s.monitoring.devths.com)"
  type        = string
  default     = "k8s.monitoring.devths.com"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_discord_webhook_nonprod" {
  description = "Discord webhook URL for nonprod alerts (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "k8s_loki_nodeport_url" {
  description = "K8s NodePort URL for in-cluster Loki (e.g. http://172.16.10.177:30100). When set, Loki/Promtail are excluded from docker-compose and Grafana uses this URL."
  type        = string
  default     = "http://172.16.10.177:30100"
}

variable "k8s_tempo_nodeport_url" {
  description = "K8s NodePort URL for in-cluster Tempo (e.g. http://172.16.10.177:32200). When set, Tempo is excluded from docker-compose and Grafana uses this URL."
  type        = string
  default     = "http://172.16.10.177:32200"
}

# ============================================================================
# Tags
# ============================================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "devths"
    Environment = "nonprod"
    ManagedBy   = "Terraform"
    Version     = "v3"
    Workload    = "kubernetes"
  }
}
