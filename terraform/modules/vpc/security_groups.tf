# ============================================================================
# Security Groups
# ============================================================================

# ALB 보안그룹 (Public tier)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-v2-${var.environment}-alb-sg"
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

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-${var.environment}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# 프런트
# ============================================================================

resource "aws_security_group" "fe" {
  name        = "${var.project_name}-v2-${var.environment}-fe-sg"
  description = "Security group for Frontend (Next.js)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-v2-${var.environment}-fe-sg" })
}

# ============================================================================
# 백엔드
# ============================================================================
resource "aws_security_group" "be" {
  name        = "${var.project_name}-v2-${var.environment}-be-sg"
  description = "Security group for Backend (Spring Boot)"
  vpc_id      = aws_vpc.this.id

  # 직접 호출(ALB -> BE)
  ingress {
    description     = "API traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-v2-${var.environment}-be-sg" })
}

# ============================================================================
# AI
# ============================================================================
resource "aws_security_group" "ai" {
  name        = "${var.project_name}-v2-${var.environment}-ai-sg"
  description = "Security group for AI service (FastAPI)"
  vpc_id      = aws_vpc.this.id

  # 직접 호출(ALB -> AI)
  ingress {
    description     = "AI API from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-v2-${var.environment}-ai-sg" })
}

# ============================================================================
# 데이터베이스
# ============================================================================
resource "aws_security_group" "database" {
  count       = length(var.database_subnet_cidrs) > 0 ? 1 : 0
  name        = "${var.project_name}-v2-${var.environment}-db-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.this.id

  # PostgreSQL from App tier
  ingress {
    description     = "PostgreSQL from App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.be.id]
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
      Name = "${var.project_name}-v2-${var.environment}-db-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
