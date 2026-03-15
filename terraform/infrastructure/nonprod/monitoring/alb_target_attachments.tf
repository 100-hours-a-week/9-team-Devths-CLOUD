# ============================================================================
# ALB 타겟 그룹 연결
# ============================================================================

# 모니터링 인스턴스를 Grafana 타겟 그룹에 연결
resource "aws_lb_target_group_attachment" "grafana" {
  target_group_arn = data.aws_lb_target_group.grafana.arn
  target_id        = module.monitoring.instance_id
  port             = 3000

  depends_on = [module.monitoring]
}
