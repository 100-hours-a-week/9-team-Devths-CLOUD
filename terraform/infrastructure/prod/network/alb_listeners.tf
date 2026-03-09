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
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.prod.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe.arn
  }

  tags = var.common_tags
}

