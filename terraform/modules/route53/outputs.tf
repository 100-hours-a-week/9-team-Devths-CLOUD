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

output "root_record_fqdn" {
  description = "FQDN of root domain record"
  value       = aws_route53_record.root.fqdn
}

output "www_record_fqdn" {
  description = "FQDN of www subdomain record"
  value       = var.create_www_record ? aws_route53_record.www[0].fqdn : null
}

output "api_record_fqdn" {
  description = "FQDN of api subdomain record"
  value       = var.create_api_record ? aws_route53_record.api[0].fqdn : null
}

output "ai_record_fqdn" {
  description = "FQDN of ai subdomain record"
  value       = var.create_ai_record ? aws_route53_record.ai[0].fqdn : null
}
