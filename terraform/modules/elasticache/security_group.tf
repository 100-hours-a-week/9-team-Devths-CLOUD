# ============================================================================
# ElastiCache Security Group
# ============================================================================

resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache ${var.engine}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-elasticache-sg"
      Environment = var.environment
      Type        = "Cache"
    }
  )
}

resource "aws_security_group_rule" "elasticache_ingress_from_app" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.elasticache.id
  description              = "Allow cache access from application security group ${count.index + 1}"
}

resource "aws_security_group_rule" "elasticache_ingress_from_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow cache access from specified CIDR blocks"
}

resource "aws_security_group_rule" "elasticache_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow all outbound traffic"
}
