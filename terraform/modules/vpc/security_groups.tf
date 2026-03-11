# ============================================================================
# Security Groups
# ============================================================================

# ALB 보안그룹 (Public tier)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.infra_version}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.this.id

  # HTTP
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# VPC Endpoints (Interface Endpoints용)
# ============================================================================
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.infra_version}-${var.environment}-vpc-interface-endpoints-sg"
  description = "Security group for VPC Interface Endpoints (ECR, etc.)"
  vpc_id      = aws_vpc.this.id

  # HTTPS from VPC
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  # 모든 outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-vpc-interface-endpoints-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
