# ============================================================================
# ElastiCache Redis (Staging)
# ============================================================================
#
# Redis 캐시 클러스터:
# - Backend 애플리케이션의 세션 및 캐싱 용도
# - be-nonprod 보안 그룹에서 접속 가능
# - Private 서브넷에 배포 (Database tier)
# ============================================================================

module "elasticache" {
  source = "../../../modules/elasticache"

  project_name  = "devths"
  environment   = "stg"
  infra_version = "v2"

  # Network configuration
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  cache_subnet_ids = data.terraform_remote_state.vpc.outputs.database_subnet_ids

  # Backend 보안 그룹에서 Redis 접속 허용
  allowed_security_group_ids = [
    data.terraform_remote_state.vpc.outputs.be_security_group_id
  ]

  # Engine settings
  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t3.small" # 프리티어 호환
  port           = 6379

  # Cluster configuration
  num_cache_clusters         = 1 # 단일 노드 (개발/스테이징 환경)
  automatic_failover_enabled = false
  multi_az_enabled           = false

  # Security settings
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  # auth_token은 transit_encryption_enabled가 true일 때 필요 (16-128자)
  # auth_token = ""  # 필요시 secrets.tfvars에서 주입

  # Backup and maintenance
  snapshot_retention_limit   = 0 # 스테이징 환경은 백업 불필요
  auto_minor_version_upgrade = true
  maintenance_window         = "sun:04:00-sun:05:00"

  # Operations
  apply_immediately = true # Non-prod는 즉시 적용

  # Custom parameters (선택사항)
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    }
  ]

  common_tags = {
    Project      = "devths"
    Environment  = "Stg"
    ManagedBy    = "Terraform"
    InfraVersion = "v2"
  }
}
