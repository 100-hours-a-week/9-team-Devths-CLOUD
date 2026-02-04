output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP (Elastic IP if enabled, otherwise instance public IP)"
  value       = var.enable_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.this.private_ip
}

output "instance_name" {
  description = "EC2 instance name"
  value       = aws_instance.this.tags["Name"]
}
