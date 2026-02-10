# Route53 모듈 - EC2 public IP 기반으로 항상 레코드 생성
module "route53" {
  source = "../../modules/route53"

  domain_name       = "devths.com"
  subdomain_prefix  = "stg"
  public_ip         = module.ec2.instance_public_ip
  create_www_record = false
  create_api_record = true
  create_ai_record  = true
  ttl               = 60

  common_tags = var.common_tags

  depends_on = [module.ec2]
}
