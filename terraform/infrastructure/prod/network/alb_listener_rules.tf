# ============================================================================
# ALB Listener Rules
# ============================================================================

# ============================================================================
# 프런트 - 민감한 엔드포인트 차단
# ============================================================================
resource "aws_lb_listener_rule" "block_fe_metrics" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  condition {
    host_header {
      values = ["www.devths.com", "devths.com"]
    }
  }

  condition {
    path_pattern {
      values = ["/api/metrics", "/api/metrics/*"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 프런트엔드 - 라우팅 규칙
# ============================================================================
# Frontend 라우팅 규칙
resource "aws_lb_listener_rule" "fe_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 390

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe.arn
  }

  condition {
    host_header {
      values = ["www.devths.com","devths.com"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 백엔드 - 민감한 엔드포인트 차단
# ============================================================================
resource "aws_lb_listener_rule" "block_be_actuator" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  condition {
    host_header {
      values = ["api.devths.com"]
    }
  }

  condition {
    path_pattern {
      values = ["/actuator/prometheus", "/actuator/prometheus/*", "/actuator/*"]
    }
  }

  tags = var.common_tags
}

resource "aws_lb_listener_rule" "block_be_swagger" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  condition {
    host_header {
      values = ["api.devths.com"]
    }
  }

  condition {
    path_pattern {
      values = ["/swagger-ui/*", "/v3/api-docs/*"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 백엔드 - 라우팅 규칙
# ============================================================================
resource "aws_lb_listener_rule" "be_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.be.arn
  }

  condition {
    host_header {
      values = ["api.devths.com"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 인공지능 - 민감한 엔드포인트 차단
# ============================================================================
resource "aws_lb_listener_rule" "block_ai_swagger" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 40

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  condition {
    host_header {
      values = ["ai.devths.com"]
    }
  }

  condition {
    path_pattern {
      values = ["/docs*", "/openapi.json"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 인공지능 - 라우팅 규칙
# ============================================================================
resource "aws_lb_listener_rule" "ai_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai.arn
  }

  condition {
    host_header {
      values = ["ai.devths.com"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 모니터링 - 라우팅 규칙
# ============================================================================

resource "aws_lb_listener_rule" "monitoring_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring.arn
  }

  condition {
    host_header {
      values = ["monitoring.devths.com"]
    }
  }

  tags = var.common_tags
}

# Frontend 라우팅 규칙 (나머지 모든 도메인 → Frontend)
# 기본 액션으로 이미 설정되어 있으므로 별도 규칙 불필요
