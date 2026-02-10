# ============================================================================
# Route 53 (Monitoring)
# ============================================================================
#
# ALB를 통한 트래픽 라우팅:
# ============================================================================

# Route53 모듈 - ALB로 라우팅
module "route53_alb" {
  source = "../../modules/route53"

  domain_name        = "devths.com"
  subdomain_prefix   = "dev"
  create_root_record = true
  create_www_record  = false
  create_api_record  = false
  create_ai_record   = false

  # ALB Alias 레코드 사용
  use_alb_alias = true
  alb_dns_name  = data.terraform_remote_state.vpc.outputs.alb_dns_name
  alb_zone_id   = data.terraform_remote_state.vpc.outputs.alb_zone_id

  common_tags = var.common_tags
}
