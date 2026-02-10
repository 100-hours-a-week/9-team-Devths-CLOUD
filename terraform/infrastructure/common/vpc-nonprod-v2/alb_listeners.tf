# ============================================================================
# ALB Listeners
# ============================================================================

# HTTP 리스너 (포트 80) - HTTPS로 리다이렉트
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # 기본 액션: HTTPS로 리다이렉트
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.common_tags
}

# HTTPS 리스너 (포트 443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  # 기본 액션: Frontend로 전달
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe.arn
  }

  tags = var.common_tags
}
