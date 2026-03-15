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
      values = ["dev.devths.com", "stg.devths.com"]
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

# 개발용 Frontend 라우팅 규칙
resource "aws_lb_listener_rule" "fe_https_dev" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 390

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_fe.arn
  }

  condition {
    host_header {
      values = ["dev.devths.com"]
    }
  }

  tags = var.common_tags
}

# 스테이징 Frontend 라우팅 규칙
resource "aws_lb_listener_rule" "fe_https_stg" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stg_fe.arn
  }

  condition {
    host_header {
      values = ["stg.devths.com"]
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
      values = ["dev.api.devths.com", "stg.api.devths.com"]
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
      values = ["dev.api.devths.com", "stg.api.devths.com"]
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

# 개발용 Backend API 라우팅 규칙
resource "aws_lb_listener_rule" "be_https_dev" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_be.arn
  }

  condition {
    host_header {
      values = ["dev.api.devths.com"]
    }
  }

  tags = var.common_tags
}

# 스테이징 Backend API 라우팅 규칙
resource "aws_lb_listener_rule" "be_https_stg" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stg_be.arn
  }

  condition {
    host_header {
      values = ["stg.api.devths.com"]
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
      values = ["dev.ai.devths.com", "stg.ai.devths.com"]
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

# 개발용 AI 라우팅 규칙
resource "aws_lb_listener_rule" "ai_https_dev" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_ai.arn
  }

  condition {
    host_header {
      values = ["dev.ai.devths.com"]
    }
  }

  tags = var.common_tags
}

# 스테이징 AI 라우팅 규칙
resource "aws_lb_listener_rule" "ai_https_stg" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 210

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stg_ai.arn
  }

  condition {
    host_header {
      values = ["stg.ai.devths.com"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# Mock - 라우팅 규칙
# ============================================================================

# 스테이징 Mock 라우팅 규칙
resource "aws_lb_listener_rule" "mock_https_stg" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 260

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stg_mock.arn
  }

  condition {
    host_header {
      values = ["mock.devths.com"]
    }
  }

  tags = var.common_tags
}

# ============================================================================
# 모니터링 - 라우팅 규칙
# ============================================================================

# 개발용/스테이징용 모니터링 라우팅 규칙
resource "aws_lb_listener_rule" "grafana_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nonprod_grafana.arn
  }

  condition {
    host_header {
      values = ["dev.monitoring.devths.com"]
    }
  }

  tags = var.common_tags
}
