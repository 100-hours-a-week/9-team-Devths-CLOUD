# ============================================================================
# Route 53 (Frontend, Backend, AI)
# ============================================================================
#
# ALB를 통한 트래픽 라우팅:
# ============================================================================

# Route53 모듈 - 모든 서브도메인을 ALB로 라우팅
module "route53_alb" {
  source = "../../modules/route53"

  domain_name        = "devths.com"
  subdomain_prefix   = "v2.dev"
  create_root_record = true
  create_www_record  = false
  create_api_record  = true
  create_ai_record   = true

  # ALB Alias 레코드 사용
  alb_dns_name  = data.terraform_remote_state.vpc.outputs.alb_dns_name
  alb_zone_id   = data.terraform_remote_state.vpc.outputs.alb_zone_id
}
