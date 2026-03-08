# ============================================================================
# ElastiCache Module - Main Configuration
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.infra_version}-${var.environment}"

  replication_group_id = trimsuffix(
    substr(replace(lower("${local.name_prefix}-cache"), "_", "-"), 0, 40),
    "-"
  )

  subnet_group_name = trimsuffix(
    substr(replace(lower("${local.name_prefix}-cache-subnet-group"), "_", "-"), 0, 255),
    "-"
  )

  parameter_group_name = trimsuffix(
    substr(replace(lower("${local.name_prefix}-${var.engine}-cache-params"), "_", "-"), 0, 255),
    "-"
  )

  parameter_group_family = var.parameter_group_family != "" ? var.parameter_group_family : (
    var.engine == "valkey" ? "valkey7" : "redis7"
  )

  automatic_failover_enabled = var.num_cache_clusters > 1 ? var.automatic_failover_enabled : false
  multi_az_enabled           = var.num_cache_clusters > 1 ? var.multi_az_enabled : false
}

resource "aws_elasticache_subnet_group" "this" {
  name        = local.subnet_group_name
  description = "ElastiCache subnet group for ${var.project_name} ${var.environment}"
  subnet_ids  = var.cache_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name        = local.subnet_group_name
      Environment = var.environment
      Type        = "Cache"
    }
  )
}

resource "aws_elasticache_parameter_group" "this" {
  name        = local.parameter_group_name
  family      = local.parameter_group_family
  description = "Custom parameter group for ${var.project_name} ${var.environment} ${var.engine}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.parameter_group_name
      Environment = var.environment
      Type        = "Cache"
    }
  )
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.replication_group_id
  description          = "ElastiCache replication group for ${var.project_name} ${var.environment}"

  engine                      = var.engine
  engine_version              = var.engine_version
  node_type                   = var.node_type
  num_cache_clusters          = var.num_cache_clusters
  port                        = var.port
  parameter_group_name        = aws_elasticache_parameter_group.this.name
  subnet_group_name           = aws_elasticache_subnet_group.this.name
  security_group_ids          = [aws_security_group.elasticache.id]
  preferred_cache_cluster_azs = length(var.preferred_cache_cluster_azs) > 0 ? var.preferred_cache_cluster_azs : null

  automatic_failover_enabled = local.automatic_failover_enabled
  multi_az_enabled           = local.multi_az_enabled

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.at_rest_encryption_enabled && var.kms_key_id != "" ? var.kms_key_id : null
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled && var.auth_token != "" ? var.auth_token : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_retention_limit > 0 ? var.snapshot_window : null
  maintenance_window         = var.maintenance_window
  notification_topic_arn     = var.notification_topic_arn != "" ? var.notification_topic_arn : null

  apply_immediately         = var.environment != "prod" ? true : var.apply_immediately
  final_snapshot_identifier = var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : null

  tags = merge(
    var.common_tags,
    {
      Name        = local.replication_group_id
      Environment = var.environment
      Type        = "Cache"
      Engine      = var.engine
    }
  )

  lifecycle {
    ignore_changes = [
      auth_token,
      final_snapshot_identifier,
    ]
  }
}
