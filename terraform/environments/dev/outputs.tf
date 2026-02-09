# VPC 결과 (공유 VPC)
output "vpc_id" {
  description = "Shared VPC ID"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}

# EC2 결과 - Frontend
output "ec2_fe_instance_id" {
  description = "Frontend EC2 instance ID"
  value       = module.ec2_fe.instance_id
}

output "ec2_fe_public_ip" {
  description = "Frontend EC2 public IP"
  value       = module.ec2_fe.instance_public_ip
}

output "ec2_fe_private_ip" {
  description = "Frontend EC2 private IP"
  value       = module.ec2_fe.instance_private_ip
}

# EC2 결과 - Backend
output "ec2_be_instance_id" {
  description = "Backend EC2 instance ID"
  value       = module.ec2_be.instance_id
}

output "ec2_be_public_ip" {
  description = "Backend EC2 public IP"
  value       = module.ec2_be.instance_public_ip
}

output "ec2_be_private_ip" {
  description = "Backend EC2 private IP"
  value       = module.ec2_be.instance_private_ip
}

# S3 Outputs
output "s3_artifact_bucket" {
  description = "Shared S3 artifact bucket name"
  value       = data.terraform_remote_state.s3.outputs.artifact_bucket_name
}

output "s3_storage_bucket" {
  description = "S3 storage bucket name"
  value       = module.s3_storage.bucket_name
}

# IAM Outputs
output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = module.iam.ec2_role_arn
}

output "codedeploy_iam_role_arn" {
  description = "CodeDeploy IAM role ARN"
  value       = module.iam.codedeploy_role_arn
}

# CodeDeploy Outputs
output "codedeploy_fe_group" {
  description = "Frontend deployment group name"
  value       = module.codedeploy_fe.deployment_group_name
}

output "codedeploy_be_group" {
  description = "Backend deployment group name"
  value       = module.codedeploy_be.deployment_group_name
}