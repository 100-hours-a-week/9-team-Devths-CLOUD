output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.monitoring.id
}

output "instance_name" {
  description = "EC2 instance name"
  value       = var.instance_name
}

output "instance_public_ip" {
  description = "EC2 instance public IP (EIP)"
  value       = aws_eip.monitoring.public_ip
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.monitoring.private_ip
}

output "monitoring_domain" {
  description = "Monitoring domain (Grafana URL)"
  value       = var.environment == "prod" ? "monitoring.${var.domain_name}" : "monitoring.dev.${var.domain_name}"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "https://${var.environment == "prod" ? "monitoring.${var.domain_name}" : "monitoring.dev.${var.domain_name}"}"
}

output "prometheus_url" {
  description = "Prometheus URL (internal)"
  value       = "http://${aws_instance.monitoring.private_ip}:9090"
}

output "security_group_id" {
  description = "Monitoring server security group ID"
  value       = aws_security_group.monitoring.id
}
