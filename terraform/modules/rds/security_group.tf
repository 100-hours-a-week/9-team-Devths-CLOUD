# ============================================================================
# RDS Security Group
# ============================================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS ${var.engine} database"
  vpc_id      = var.vpc_id

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-rds-sg"
      Environment = var.environment
      Type        = "Database"
    }
  )
}

# Ingress: Allow from Backend security groups
resource "aws_security_group_rule" "rds_ingress_from_app" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.rds.id
  description              = "Allow ${var.engine} access from application security group ${count.index + 1}"
}

# Ingress: Allow from CIDR blocks (if specified)
resource "aws_security_group_rule" "rds_ingress_from_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.rds.id
  description       = "Allow ${var.engine} access from specified CIDR blocks"
}

# Egress: Allow all outbound (required for software updates)
resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}
