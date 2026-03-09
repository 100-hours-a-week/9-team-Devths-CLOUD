# ============================================================================
# 프로젝트 공통
# ============================================================================
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devths"
}

# 환경 정의
variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

# 인프라 버전
variable "infra_version" {
  description = "Infrastructure version (v1, v2)"
  type        = string
  default     = "v2"
}

# VPC 설정
variable "vpc_id" {
  description = "VPC ID where ElastiCache will be deployed"
  type        = string
}

# 서브넷
variable "cache_subnet_ids" {
  description = "List of subnet IDs for ElastiCache subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access ElastiCache"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access ElastiCache"
  type        = list(string)
  default     = []
}

# 엔진 설정
variable "engine" {
  description = "Cache engine (redis or valkey)"
  type        = string
  default     = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "engine must be either redis or valkey."
  }
}

variable "engine_version" {
  description = "Cache engine version"
  type        = string
  default     = "7.1"
}

# 파라미터 그룹
variable "parameter_group_family" {
  description = "ElastiCache parameter group family (optional, defaults by engine)"
  type        = string
  default     = ""
}

variable "parameters" {
  description = "List of custom ElastiCache parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# 노드 설정
variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "port" {
  description = "ElastiCache port"
  type        = number
  default     = 6379

  validation {
    condition     = var.port > 0 && var.port < 65536
    error_message = "port must be between 1 and 65535."
  }
}

variable "num_cache_clusters" {
  description = "Number of cache clusters in replication group"
  type        = number
  default     = 1

  validation {
    condition     = var.num_cache_clusters >= 1
    error_message = "num_cache_clusters must be greater than or equal to 1."
  }
}

variable "preferred_cache_cluster_azs" {
  description = "Preferred AZs for cache clusters (optional)"
  type        = list(string)
  default     = []
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (recommended when using 2+ nodes)"
  type        = bool
  default     = false
}

# 다중 AZ
variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment (requires automatic failover)"
  type        = bool
  default     = false
}

# 암호화
variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN/ID for encryption at rest (optional)"
  type        = string
  default     = ""
}

# 전송 암호화
variable "transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "AUTH token for Redis/Valkey (optional, requires transit_encryption_enabled)"
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.auth_token == "" || (length(var.auth_token) >= 16 && length(var.auth_token) <= 128)
    error_message = "auth_token length must be between 16 and 128 characters when provided."
  }
}

# 마이너 버전 업데이트
variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots (0 to disable)"
  type        = number
  default     = 0

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "snapshot_retention_limit must be between 0 and 35."
  }
}

variable "snapshot_window" {
  description = "Daily time range in UTC for snapshots"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly time range in UTC for maintenance"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for ElastiCache notifications (optional)"
  type        = string
  default     = ""
}

variable "apply_immediately" {
  description = "Apply modifications immediately (prod usually false)"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier when deleting replication group (optional)"
  type        = string
  default     = ""
}

# ============================================================================
# 공통 태그
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
