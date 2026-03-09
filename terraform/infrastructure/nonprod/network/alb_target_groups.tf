# ============================================================================
# ALB 타겟그룹
# ============================================================================

# ============================================================================
# 프런트엔드 - 타겟그룹
# ============================================================================

# 개발용 - 프런트엔드
resource "aws_lb_target_group" "dev_fe" {
  name     = "${var.project_name}-${var.infra_version}-dev-fe-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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
      Name        = "${var.project_name}-${var.infra_version}-dev-fe-tg"
      Service     = "Frontend"
      Environment = "dev"
    }
  )
}

# 스테이징 - 프런트엔드
resource "aws_lb_target_group" "stg_fe" {
  name     = "${var.project_name}-${var.infra_version}-stg-fe-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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
      Name        = "${var.project_name}-${var.infra_version}-stg-fe-tg"
      Service     = "Frontend"
      Environment = "stg"
    }
  )
}

# ============================================================================
# 백엔드 - 타겟그룹
# ============================================================================

# 개발용 - 백엔드
resource "aws_lb_target_group" "dev_be" {
  name     = "${var.project_name}-${var.infra_version}-dev-be-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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
      Name        = "${var.project_name}-${var.infra_version}-dev-be-tg"
      Service     = "Backend"
      Environment = "dev"
    }
  )
}

# 스테이징 - 백엔드
resource "aws_lb_target_group" "stg_be" {
  name     = "${var.project_name}-${var.infra_version}-stg-be-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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
      Name        = "${var.project_name}-${var.infra_version}-stg-be-tg"
      Service     = "Backend"
      Environment = "stg"
    }
  )
}

# ============================================================================
# 인공지능 - 타겟그룹
# ============================================================================

# 개발용 - 인공지능
resource "aws_lb_target_group" "dev_ai" {
  name     = "${var.project_name}-${var.infra_version}-dev-ai-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.infra_version}-dev-ai-tg"
      Service     = "Ai"
      Environment = "dev"
    }
  )
}

# 스테이징 - 인공지능
resource "aws_lb_target_group" "stg_ai" {
  name     = "${var.project_name}-${var.infra_version}-stg-ai-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.infra_version}-stg-ai-tg"
      Service     = "Ai"
      Environment = "stg"
    }
  )
}

# ============================================================================
# Mock
# ============================================================================

# 스테이징 - Mock
resource "aws_lb_target_group" "stg_mock" {
  name     = "${var.project_name}-${var.infra_version}-stg-mock-tg"
  port     = 8082
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/__admin/health"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  # 커넥션 드레이닝
  deregistration_delay = 30

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.infra_version}-stg-mock-tg"
      Service     = "Mock"
      Environment = "stg"
    }
  )
}

# ============================================================================
# 모니터링
# ============================================================================

# 모니터링 - NonProd
resource "aws_lb_target_group" "nonprod_grafana" {
  name     = "${var.project_name}-${var.infra_version}-nonprod-grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # 헬스체크
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
      Name        = "${var.project_name}-${var.infra_version}-nonprod-grafana-tg"
      Service     = "Grafana"
      Environment = "nonprod"
    }
  )
}




