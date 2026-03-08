# 모니터링 서버 전용 Security Group
resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-v2-${var.environment}-monitor-sg"
  description = "Security group for monitoring server (Prometheus + Grafana)"
  vpc_id      = var.vpc_id

  # Grafana (ALB → Grafana)
  ingress {
    description     = "Grafana from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Prometheus (내부 전용 - VPC 내에서만 접근 가능)
  ingress {
    description = "Prometheus from VPC"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Loki (내부 전용 - VPC 내에서만 접근 가능)
  ingress {
    description = "Loki from VPC"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # 모든 outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      ingress,
      egress,
    ]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-${var.environment}-monitor-sg"
      Type = "Monitoring"
    }
  )
}
