# ============================================================================
# RDS Module - Outputs
# ============================================================================

# RDS Instance 정보
output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_engine" {
  description = "Database engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version" {
  description = "Database engine version"
  value       = aws_db_instance.this.engine_version_actual
}

output "db_instance_resource_id" {
  description = "RDS resource ID"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.this.status
}

# JDBC URL (for Spring Boot)
output "jdbc_url" {
  description = "JDBC connection URL for Spring Boot"
  value       = "jdbc:${var.engine}://${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
}

# 보안 그룹
output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "security_group_name" {
  description = "RDS security group name"
  value       = aws_security_group.rds.name
}

# 서브넷 그룹
output "db_subnet_group_id" {
  description = "Database subnet group ID"
  value       = aws_db_subnet_group.this.id
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.this.name
}

# 파라미터 그룹
output "parameter_group_id" {
  description = "Database parameter group ID"
  value       = aws_db_parameter_group.this.id
}

output "parameter_group_name" {
  description = "Database parameter group name"
  value       = aws_db_parameter_group.this.name
}

# 모니터링 정보
output "monitoring_role_arn" {
  description = "Enhanced monitoring IAM role ARN"
  value       = var.monitoring_interval > 0 ? var.monitoring_role_arn : null
}

output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_db_instance.this.performance_insights_enabled
}
