# ==============================================================================
# EC2 Module Outputs
# ==============================================================================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance (if assigned)"
  value       = aws_instance.this.public_ip
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.this.availability_zone
}

output "ami_id" {
  description = "AMI ID used for the EC2 instance"
  value       = aws_instance.this.ami
}
