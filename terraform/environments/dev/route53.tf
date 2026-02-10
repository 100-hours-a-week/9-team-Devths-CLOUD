# ============================================================================
# Route 53 (Frontend, Backend, AI)
# ============================================================================

# Route53 모듈 - Frontend (v2.dev.devths.com)
module "route53_fe" {
  source = "../../modules/route53"

  domain_name        = "devths.com"
  subdomain_prefix   = "v2.dev"
  public_ip          = module.ec2_fe.instance_public_ip
  create_root_record = true
  create_www_record  = false
  create_api_record  = false
  create_ai_record   = false
  ttl                = 60

  common_tags = var.common_tags

  depends_on = [module.ec2_fe]
}

# Route53 모듈 - Backend (v2.dev.api.devths.com)
module "route53_be" {
  source = "../../modules/route53"

  domain_name        = "devths.com"
  subdomain_prefix   = "v2.dev"
  public_ip          = module.ec2_be.instance_public_ip
  create_root_record = false
  create_www_record  = false
  create_api_record  = true
  create_ai_record   = false
  ttl                = 60

  common_tags = var.common_tags

  depends_on = [module.ec2_be]
}

# Route53 모듈 - AI (v2.dev.ai.devths.com)
module "route53_ai" {
  source = "../../modules/route53"

  domain_name        = "devths.com"
  subdomain_prefix   = "v2.dev"
  public_ip          = module.ec2_ai.instance_public_ip
  create_root_record = false
  create_www_record  = false
  create_api_record  = false
  create_ai_record   = true
  ttl                = 60

  common_tags = var.common_tags

  depends_on = [module.ec2_ai]
}
