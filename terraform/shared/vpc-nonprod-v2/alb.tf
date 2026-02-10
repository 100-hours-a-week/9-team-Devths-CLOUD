# ============================================================================
# Application Load Balancer (ALB)
# ============================================================================

# ALB 생성
resource "aws_lb" "this" {
  name               = "${var.project_name}-v2-nonprod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.alb_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-nonprod-alb"
    }
  )
}

# ============================================================================
# Target Groups (태그 기반)
# ============================================================================

# Target Group - Frontend (FE)
resource "aws_lb_target_group" "fe" {
  name     = "${var.project_name}-v2-nonprod-fe-tg"
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

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-v2-nonprod-fe-tg"
      Service = "Frontend"
    }
  )
}

# Target Group - Backend (BE)
resource "aws_lb_target_group" "be" {
  name     = "${var.project_name}-v2-nonprod-be-tg"
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

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-v2-nonprod-be-tg"
      Service = "Backend"
    }
  )
}

# Target Group - AI
resource "aws_lb_target_group" "ai" {
  name     = "${var.project_name}-v2-nonprod-ai-tg"
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

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-v2-nonprod-ai-tg"
      Service = "Ai"
    }
  )
}

# ============================================================================
# Target Group Attachments (태그 기반 자동 등록)
# ============================================================================

# EC2 인스턴스를 태그 기반으로 자동 등록하는 데이터 소스
data "aws_instances" "fe" {
  filter {
    name   = "tag:Service"
    values = ["Frontend"]
  }

  filter {
    name   = "tag:Project"
    values = ["devths"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "be" {
  filter {
    name   = "tag:Service"
    values = ["Backend"]
  }

  filter {
    name   = "tag:Project"
    values = ["devths"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "ai" {
  filter {
    name   = "tag:Service"
    values = ["Ai"]
  }

  filter {
    name   = "tag:Project"
    values = ["devths"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Target Group Attachment - Frontend
resource "aws_lb_target_group_attachment" "fe" {
  count            = length(data.aws_instances.fe.ids)
  target_group_arn = aws_lb_target_group.fe.arn
  target_id        = data.aws_instances.fe.ids[count.index]
  port             = 3000
}

# Target Group Attachment - Backend
resource "aws_lb_target_group_attachment" "be" {
  count            = length(data.aws_instances.be.ids)
  target_group_arn = aws_lb_target_group.be.arn
  target_id        = data.aws_instances.be.ids[count.index]
  port             = 8080
}

# Target Group Attachment - AI
resource "aws_lb_target_group_attachment" "ai" {
  count            = length(data.aws_instances.ai.ids)
  target_group_arn = aws_lb_target_group.ai.arn
  target_id        = data.aws_instances.ai.ids[count.index]
  port             = 8000
}

# ============================================================================
# ALB Listeners
# ============================================================================

# HTTP 리스너 (포트 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # 기본 액션: Frontend로 포워딩
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe.arn
  }

  tags = var.common_tags
}

# HTTPS 리스너 (포트 443) - 인증서가 있을 때 활성화
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe.arn
  }

  tags = var.common_tags
}

# ============================================================================
# Listener Rules (호스트 기반 라우팅)
# ============================================================================

# Backend API 라우팅 규칙 (*.api.devths.com → Backend)
resource "aws_lb_listener_rule" "be" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.be.arn
  }

  condition {
    host_header {
      values = ["*.api.devths.com", "api.devths.com"]
    }
  }

  tags = var.common_tags
}

# AI 라우팅 규칙 (*.ai.devths.com → AI)
resource "aws_lb_listener_rule" "ai" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai.arn
  }

  condition {
    host_header {
      values = ["*.ai.devths.com", "ai.devths.com"]
    }
  }

  tags = var.common_tags
}

# Frontend 라우팅 규칙 (나머지 모든 도메인 → Frontend)
# 기본 액션으로 이미 설정되어 있으므로 별도 규칙 불필요
