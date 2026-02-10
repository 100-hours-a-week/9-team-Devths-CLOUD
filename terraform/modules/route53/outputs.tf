# ========================================
# 호스팅 존 정보
# ========================================

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.this.zone_id
}

output "zone_name" {
  description = "Route53 hosted zone name"
  value       = data.aws_route53_zone.this.name
}

output "name_servers" {
  description = "Route53 hosted zone name servers"
  value       = data.aws_route53_zone.this.name_servers
}

# ========================================
# 애플리케이션 서비스 레코드 (ALB Alias)
# ========================================

output "root_record_fqdn" {
  description = "FQDN of root domain record"
  value       = var.create_root_record ? aws_route53_record.root[0].fqdn : null
}

output "www_record_fqdn" {
  description = "FQDN of www subdomain record"
  value       = var.create_www_record && var.subdomain_prefix == "" ? aws_route53_record.www[0].fqdn : null
}

output "api_record_fqdn" {
  description = "FQDN of api subdomain record"
  value       = var.create_api_record ? aws_route53_record.api[0].fqdn : null
}

output "ai_record_fqdn" {
  description = "FQDN of ai subdomain record"
  value       = var.create_ai_record ? aws_route53_record.ai[0].fqdn : null
}

output "monitoring_record_fqdn" {
  description = "FQDN of monitoring subdomain record"
  value       = var.create_monitoring_record ? aws_route53_record.monitoring[0].fqdn : null
}
