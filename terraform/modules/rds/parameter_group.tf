# ============================================================================
# RDS Parameter Group
# ============================================================================

resource "aws_db_parameter_group" "this" {
  name        = "${var.project_name}-${var.environment}-${var.engine}-params"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${var.project_name} ${var.environment} ${var.engine}"

  # Custom parameters (if provided)
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.engine}-params"
      Environment = var.environment
      Type        = "Database"
    }
  )
}
