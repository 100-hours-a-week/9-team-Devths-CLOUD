# ============================================================================
# ALB 타겟그룹
# ============================================================================

# ============================================================================
# 프런트엔드 - 타겟그룹
# ============================================================================

resource "aws_lb_target_group" "fe" {
  name     = "${var.project_name}-${var.infra_version}-${var.environment}-fe-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  # 커넥션 드레이닝
  deregistration_delay = 30

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-${var.infra_version}-${var.environment}-fe-tg"
      Service = "Frontend"
    }
  )
}

# ============================================================================
# 백엔드 - 타겟그룹
# ============================================================================

resource "aws_lb_target_group" "be" {
  name     = "${var.project_name}-${var.infra_version}-${var.environment}-be-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  # 커넥션 드레이닝
  deregistration_delay = 30

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-${var.infra_version}-${var.environment}-be-tg"
      Service = "Backend"
    }
  )
}

# ============================================================================
# 인공지능 - 타겟그룹
# ============================================================================

resource "aws_lb_target_group" "ai" {
  name     = "${var.project_name}-${var.infra_version}-${var.environment}-ai-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  # 커넥션 드레이닝
  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-${var.infra_version}-${var.environment}-ai-tg"
      Service = "Ai"
    }
  )
}

# ============================================================================
# 모니터링 - 타겟그룹
# ============================================================================

resource "aws_lb_target_group" "monitoring" {
  name     = "${var.project_name}-${var.infra_version}-${var.environment}-mon-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  # 커넥션 드레이닝
  deregistration_delay = 30

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-${var.infra_version}-${var.environment}-mon-tg"
      Service = "Monitoring"
    }
  )
}
