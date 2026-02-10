# ============================================================================
# ALB Listener Rules (호스트 기반 라우팅)
# ============================================================================

# Backend API 라우팅 규칙 (*.api.devths.com → Backend)
resource "aws_lb_listener_rule" "be_https" {
  listener_arn = aws_lb_listener.https.arn
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
resource "aws_lb_listener_rule" "ai_https" {
  listener_arn = aws_lb_listener.https.arn
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

# Monitoring 라우팅 규칙 (monitoring.dev.devths.com → Monitoring)
resource "aws_lb_listener_rule" "monitoring_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring.arn
  }

  condition {
    host_header {
      values = ["dev.monitoring.devths.com"]
    }
  }

  tags = var.common_tags
}

# Frontend 라우팅 규칙 (나머지 모든 도메인 → Frontend)
# 기본 액션으로 이미 설정되어 있으므로 별도 규칙 불필요
