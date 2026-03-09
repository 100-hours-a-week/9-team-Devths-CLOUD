output "vpc_id" {
  description = "NonProd VPC ID"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}

# ============================================================================
# S3
# ============================================================================

output "s3_artifact_bucket" {
  description = "Shared S3 artifact bucket name"
  value       = data.terraform_remote_state.s3.outputs.artifact_bucket_name
}

output "s3_storage_bucket" {
  description = "S3 storage bucket name"
  value       = module.s3_storage.bucket_name
}

# ============================================================================
# IAM
# ============================================================================

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = module.iam.ec2_role_arn
}

output "codedeploy_iam_role_arn" {
  description = "CodeDeploy IAM role ARN"
  value       = module.iam.codedeploy_role_arn
}

# ============================================================================
# Code Deploy
# ============================================================================

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

# ============================================================================
# ASG - 프런트엔드
# ============================================================================

output "asg_fe_name" {
  description = "Frontend ASG name"
  value       = module.asg_fe.asg_name
}

output "asg_fe_arn" {
  description = "Frontend ASG ARN"
  value       = module.asg_fe.asg_arn
}

output "asg_fe_launch_template_id" {
  description = "Frontend 시작 템플릿 ID"
  value       = module.asg_fe.launch_template_id
}

# ============================================================================
# ASG - 백엔드
# ============================================================================

output "asg_be_name" {
  description = "Backend ASG name"
  value       = module.asg_be.asg_name
}

output "asg_be_arn" {
  description = "Backend ASG ARN"
  value       = module.asg_be.asg_arn
}

output "asg_be_launch_template_id" {
  description = "Backend 시작 템플릿 ID"
  value       = module.asg_be.launch_template_id
}

# ============================================================================
# ASG - 인공지능
# ============================================================================

output "asg_ai_name" {
  description = "AI ASG name"
  value       = module.asg_ai.asg_name
}

output "asg_ai_arn" {
  description = "AI ASG ARN"
  value       = module.asg_ai.asg_arn
}

output "asg_ai_launch_template_id" {
  description = "AI 시작 템플릿 ID"
  value       = module.asg_ai.launch_template_id
}

# ============================================================================
# RDS
# ============================================================================

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = module.rds.db_instance_id
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_instance_address" {
  description = "RDS instance hostname"
  value       = module.rds.db_instance_address
}

output "rds_jdbc_url" {
  description = "JDBC connection URL for Spring Boot"
  value       = module.rds.jdbc_url
  sensitive   = true
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
}