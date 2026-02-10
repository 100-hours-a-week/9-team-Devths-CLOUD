# 호스팅 존
output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.this.zone_id
}

# ZONE
output "zone_name" {
  description = "Route53 hosted zone name"
  value       = data.aws_route53_zone.this.name
}

# 네임서버
output "name_servers" {
  description = "Route53 hosted zone name servers"
  value       = data.aws_route53_zone.this.name_servers
}

# 루트
output "root_record_fqdn" {
  description = "FQDN of root domain record"
  value = var.create_root_record ? (
    var.use_alb_alias ? aws_route53_record.root_alias[0].fqdn : aws_route53_record.root[0].fqdn
  ) : null
}

# WWW
output "www_record_fqdn" {
  description = "FQDN of www subdomain record"
  value = var.create_www_record && var.subdomain_prefix == "" ? (
    var.use_alb_alias ? aws_route53_record.www_alias[0].fqdn : aws_route53_record.www[0].fqdn
  ) : null
}

# API
output "api_record_fqdn" {
  description = "FQDN of api subdomain record"
  value = var.create_api_record ? (
    var.use_alb_alias ? aws_route53_record.api_alias[0].fqdn : aws_route53_record.api[0].fqdn
  ) : null
}

# AI
output "ai_record_fqdn" {
  description = "FQDN of ai subdomain record"
  value = var.create_ai_record ? (
    var.use_alb_alias ? aws_route53_record.ai_alias[0].fqdn : aws_route53_record.ai[0].fqdn
  ) : null
}
