# ============================================================================
# Route53 DNS Records
# ============================================================================

# Route53 모듈 - Grafana 도메인을 ALB로 라우팅
module "route53_monitoring" {
  source = "../../modules/route53"

  domain_name              = var.domain_name
  subdomain_prefix         = "dev"
  create_root_record       = false
  create_www_record        = false
  create_api_record        = false
  create_ai_record         = false
  create_monitoring_record = true

  # ALB Alias 레코드 사용
  alb_dns_name = data.terraform_remote_state.vpc.outputs.alb_dns_name
  alb_zone_id  = data.terraform_remote_state.vpc.outputs.alb_zone_id

  depends_on = [module.monitoring]
}
