output "monitoring_instance_id" {
  description = "Monitoring server instance ID"
  value       = module.monitoring.instance_id
}

output "monitoring_instance_name" {
  description = "Monitoring server instance name"
  value       = module.monitoring.instance_name
}

output "monitoring_private_ip" {
  description = "Monitoring server private IP"
  value       = module.monitoring.instance_private_ip
}

output "monitoring_domain" {
  description = "Monitoring domain"
  value       = module.monitoring.monitoring_domain
}

output "grafana_url" {
  description = "Grafana URL"
  value       = module.monitoring.grafana_url
}

output "prometheus_url" {
  description = "Prometheus URL (internal)"
  value       = module.monitoring.prometheus_url
}

output "route53_record" {
  description = "Route53 DNS record"
  value       = aws_route53_record.monitoring.fqdn
}

output "monitoring_security_group_id" {
  description = "Monitoring server security group ID"
  value       = module.monitoring.security_group_id
}
