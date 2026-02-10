output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "EC2 공인 IP"
  value       = var.enable_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "instance_private_ip" {
  description = "EC2 인스턴스 private IP"
  value       = aws_instance.this.private_ip
}

output "instance_name" {
  description = "EC2 인스턴스 name"
  value       = aws_instance.this.tags["Name"]
}
