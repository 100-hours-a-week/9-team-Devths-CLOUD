# ============================================================================
# Route 53 (Frontend, Backend, AI)
# ============================================================================
#
# ALB를 통한 트래픽 라우팅:
# - stg.devths.com      → ALB → Frontend Target Group
# - stg.api.devths.com  → ALB → Backend Target Group
# - stg.ai.devths.com   → ALB → AI Target Group
# - mock.devths.com → ALB → Mock Target Group
# ============================================================================

# Route53 모듈 - 가중치 기반 라우팅으로 V1/V2 병행 운영
module "route53_alb" {
  source = "../../../modules/route53"

  domain_name        = "devths.com"
  subdomain_prefix   = "stg"
  create_root_record = true # Frontend (stg.devths.com)도 가중치 기반 라우팅 적용
  create_www_record  = false
  create_api_record  = true
  create_ai_record   = true

  # ALB Alias 레코드 사용 (V2)
  alb_dns_name = data.terraform_remote_state.vpc.outputs.alb_dns_name
  alb_zone_id  = data.terraform_remote_state.vpc.outputs.alb_zone_id

  # 가중치 기반 라우팅 활성화 (V1 <-> V2 점진적 전환)
  enable_weighted_routing = true
  v1_instance_ip          = "3.39.253.162" # 기존 V1 EC2 인스턴스
  v1_weight               = 0              # V1 트래픽 비율 (0-255)
  v2_weight               = 255            # V2 트래픽 비율 (0-255)

  # 스케줄링으로 인스턴스가 0개가 될 수 있으므로 타겟 헬스 체크 비활성화
  evaluate_target_health = false
}

# Mock 전용 레코드
resource "aws_route53_record" "mock" {
  zone_id = module.route53_alb.zone_id
  name    = "mock.devths.com"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.vpc.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.vpc.outputs.alb_zone_id
    evaluate_target_health = false
  }
}
