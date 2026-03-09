# ============================================================================
# ALB Listeners
# ============================================================================

# HTTP 리스너 (포트 80)
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
  certificate_arn   = data.aws_acm_certificate.dev.arn

  # 기본 액션: 개발용 프런트엔드로 이동
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_fe.arn
  }

  tags = var.common_tags
}

# ============================================================================
# ALB Listeners + ACM 연결
# ============================================================================

resource "aws_lb_listener_certificate" "stg" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.stg.arn
}

resource "aws_lb_listener_certificate" "dev_monitoring" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.dev_monitoring.arn
}
