# ============================================================================
# ElastiCache Module - Outputs
# ============================================================================

output "replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ElastiCache replication group ARN"
  value       = aws_elasticache_replication_group.this.arn
}

output "engine" {
  description = "Cache engine"
  value       = var.engine
}

output "engine_version_actual" {
  description = "Actual engine version running on ElastiCache"
  value       = aws_elasticache_replication_group.this.engine_version_actual
}

output "primary_endpoint_address" {
  description = "Primary endpoint address (writer)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address (cluster mode enabled)"
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}

output "port" {
  description = "Cache port"
  value       = var.port
}

output "primary_endpoint" {
  description = "Primary endpoint in host:port format"
  value       = "${aws_elasticache_replication_group.this.primary_endpoint_address}:${var.port}"
}

output "member_clusters" {
  description = "List of member cache clusters"
  value       = aws_elasticache_replication_group.this.member_clusters
}

output "security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.elasticache.id
}

output "security_group_name" {
  description = "ElastiCache security group name"
  value       = aws_security_group.elasticache.name
}

output "subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.this.name
}

output "subnet_group_id" {
  description = "ElastiCache subnet group ID"
  value       = aws_elasticache_subnet_group.this.id
}

output "parameter_group_name" {
  description = "ElastiCache parameter group name"
  value       = aws_elasticache_parameter_group.this.name
}

output "parameter_group_id" {
  description = "ElastiCache parameter group ID"
  value       = aws_elasticache_parameter_group.this.id
}

output "auth_token_enabled" {
  description = "Whether auth token is configured"
  value       = var.auth_token != ""
  sensitive   = true
}
