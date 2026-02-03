# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# EC2 Outputs
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.instance_public_ip
}

output "ec2_private_ip" {
  description = "EC2 private IP"
  value       = module.ec2.instance_private_ip
}

# S3 Outputs
output "s3_artifact_bucket" {
  description = "S3 artifact bucket name"
  value       = module.s3_artifact.bucket_name
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

output "codedeploy_ai_group" {
  description = "AI deployment group name"
  value       = module.codedeploy_ai.deployment_group_name
}

# SSM Outputs
output "ssm_log_bucket" {
  description = "S3 bucket for SSM session logs"
  value       = module.ssm.ssm_log_bucket_id
}

output "ssm_cloudwatch_log_group" {
  description = "CloudWatch Log Group for SSM sessions"
  value       = module.ssm.cloudwatch_log_group_name
}
