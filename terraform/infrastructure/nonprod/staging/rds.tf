# ============================================================================
# RDS Database (PostgreSQL)
# ============================================================================

module "rds" {
  source = "../../../modules/rds"

  # 프로젝트 정보
  project_name  = var.project_name
  environment   = var.environment
  infra_version = var.infra_version

  # 네트워크 설정
  vpc_id                     = data.terraform_remote_state.vpc.outputs.vpc_id
  database_subnet_ids        = data.terraform_remote_state.vpc.outputs.database_subnet_ids
  allowed_security_group_ids = [data.terraform_remote_state.vpc.outputs.be_security_group_id]

  # 데이터베이스 엔진 설정
  engine                 = "postgres"
  engine_version         = "16.11"
  parameter_group_family = "postgres16"

  # 인스턴스 설정
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # 데이터베이스 자격 증명 (secrets.tfvars에서 주입)
  db_name     = var.rds_db_name
  db_username = var.rds_db_username
  db_password = var.rds_db_password
  db_port     = 5432

  # 백업 설정
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"         # UTC (한국 시간 12:00-13:00)
  maintenance_window      = "mon:04:00-mon:05:00" # UTC (한국 시간 월 13:00-14:00)
  skip_final_snapshot     = true                  # Staging 환경은 final snapshot 생성 안함

  # 고가용성 설정 (Staging 환경은 비활성화)
  multi_az            = false
  availability_zone   = "ap-northeast-2a" # 비용 절감을 위해 단일 AZ 사용
  publicly_accessible = false

  # 성능 및 모니터링 (Staging 환경은 비활성화로 비용 절감)
  performance_insights_enabled    = false
  monitoring_interval             = 0
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # PostgreSQL 파라미터 설정 (선택사항)
  parameters = [
    {
      name         = "log_connections"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_disconnections"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_duration"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_min_duration_statement"
      value        = "1000" # 1초 이상 걸리는 쿼리 로깅
      apply_method = "immediate"
    }
  ]

  # 삭제 보호 (Staging 환경은 비활성화)
  deletion_protection        = false
  auto_minor_version_upgrade = true

  # 태그
  common_tags = merge(
    var.common_tags,
    {
      Service = "Database"
    }
  )
}
