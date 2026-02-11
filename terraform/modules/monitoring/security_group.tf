# 모니터링 서버 전용 Security Group
resource "aws_security_group" "monitoring" {
  name        = "${var.instance_name}-sg"
  description = "Security group for monitoring server (Prometheus + Grafana)"
  vpc_id      = var.vpc_id

  # HTTP (Let's Encrypt 인증서 발급용)
  ingress {
    description = "HTTP for SSL cert provisioning"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (Grafana 웹 인터페이스)
  ingress {
    description = "HTTPS for Grafana"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana (ALB → Grafana)
  ingress {
    description     = "Grafana from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Prometheus (ALB → Prometheus)
  ingress {
    description     = "Prometheus from ALB"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Prometheus (내부 접근 - VPC 내에서도 접근 가능)
  ingress {
    description = "Prometheus from VPC"
    from_port   = 9090
    to_port     = 9090
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

  tags = merge(
    var.common_tags,
    {
      Name = "${var.instance_name}-sg"
      Type = "Monitoring"
    }
  )
}
