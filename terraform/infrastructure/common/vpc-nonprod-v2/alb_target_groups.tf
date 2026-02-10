# ============================================================================
# ALB Target Groups
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

# Target Group - Monitoring (Grafana via Nginx)
resource "aws_lb_target_group" "monitoring" {
  name     = "${var.project_name}-v2-nonprod-mon-tg"
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
      Name    = "${var.project_name}-v2-nonprod-mon-tg"
      Service = "Monitoring"
    }
  )
}
