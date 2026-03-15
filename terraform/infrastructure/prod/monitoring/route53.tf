# ============================================================================
# Route53 DNS Records
# ============================================================================

# Route53 Alias 레코드 - ALB를 통해 모니터링 서버 접근
resource "aws_route53_record" "monitoring" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "monitoring.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.prod.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.prod.outputs.alb_zone_id
    evaluate_target_health = true
  }

  depends_on = [module.monitoring]
}
