# ============================================================================
# Route 53 (Prod)
# ============================================================================

module "route53" {
  source = "../../../modules/route53"

  domain_name                = "devths.com"
  subdomain_prefix           = ""
  create_root_record         = true
  create_www_record          = true
  create_api_record          = true
  create_ai_record           = true
  create_monitoring_record   = true
  alb_dns_name               = data.terraform_remote_state.network.outputs.alb_dns_name
  alb_zone_id                = data.terraform_remote_state.network.outputs.alb_zone_id
  enable_weighted_routing    = var.route53_enable_weighted_routing
  create_v1_weighted_records = var.route53_create_v1_weighted_records
  v1_instance_ip             = var.route53_v1_instance_ip
  v1_weight                  = var.route53_v1_weight
  v2_weight                  = var.route53_v2_weight
  evaluate_target_health     = var.route53_evaluate_target_health
}
