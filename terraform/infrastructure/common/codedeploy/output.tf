# ============================================================================
# 프런트 엔드
# ============================================================================
output "codedeploy_app_fe_name" {
  description = "CodeDeploy application name for Frontend"
  value       = aws_codedeploy_app.fe.name
}


# ============================================================================
# 백엔드
# ============================================================================
output "codedeploy_app_be_name" {
  description = "CodeDeploy application name for Backend"
  value       = aws_codedeploy_app.be.name
}


# ============================================================================
# 인공지능
# ============================================================================
output "codedeploy_app_ai_name" {
  description = "CodeDeploy application name for AI"
  value       = aws_codedeploy_app.ai.name
}
