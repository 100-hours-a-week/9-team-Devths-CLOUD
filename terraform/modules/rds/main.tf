# ============================================================================
# RDS Module - Main Configuration
# ============================================================================

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.infra_version}-${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.project_name} ${var.infra_version} ${var.environment}"
  subnet_ids  = var.database_subnet_ids

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.infra_version}-${var.environment}-db-subnet-group"
      Environment = var.environment
      Type        = "Database"
    }
  )
}

# RDS Instance
resource "aws_db_instance" "this" {
  # 식별자
  identifier = "${var.project_name}-${var.infra_version}-${var.environment}-rds"

  # 엔진 설정
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # 스토리지 설정
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.storage_encrypted && var.kms_key_id != "" ? var.kms_key_id : null

  # 데이터베이스 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  # 파라미터 그룹
  parameter_group_name = aws_db_parameter_group.this.name

  # 고가용성
  multi_az          = var.multi_az
  availability_zone = var.multi_az ? null : var.availability_zone

  # 백업 설정
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != "" ?
    "${var.final_snapshot_identifier}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" :
    "${var.project_name}-${var.infra_version}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )
  copy_tags_to_snapshot = true

  # 성능 및 모니터링
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # 업데이트 및 보호
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  deletion_protection        = var.deletion_protection
  apply_immediately          = var.environment != "prod" ? true : false

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.infra_version}-${var.environment}-rds"
      Environment = var.environment
      Type        = "Database"
      Engine      = var.engine
    }
  )

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier,
    ]
  }
}
