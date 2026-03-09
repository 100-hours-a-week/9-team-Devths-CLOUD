# ============================================================================
# VPC
# ============================================================================
output "vpc_id" {
  description = "Shared VPC ID"
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

# ============================================================================
# Code Deploy
# ============================================================================
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

# ============================================================================
# ASG
# ============================================================================
# 프런트엔드
output "asg_fe_name" {
  description = "Frontend ASG name"
  value       = module.asg_fe.asg_name
}

output "asg_fe_arn" {
  description = "Frontend ASG ARN"
  value       = module.asg_fe.asg_arn
}

# 백엔드
output "asg_be_name" {
  description = "Backend ASG name"
  value       = module.asg_be.asg_name
}

output "asg_be_arn" {
  description = "Backend ASG ARN"
  value       = module.asg_be.asg_arn
}

# 인공지능
output "asg_ai_name" {
  description = "AI ASG name"
  value       = module.asg_ai.asg_name
}

output "asg_ai_arn" {
  description = "AI ASG ARN"
  value       = module.asg_ai.asg_arn
}

# ============================================================================
# ASG 시작 템플릿
# ============================================================================

# 프런트엔드
output "asg_fe_launch_template_id" {
  description = "Frontend 시작 템플릿 ID"
  value       = module.asg_fe.launch_template_id
}

# 백엔드
output "asg_be_launch_template_id" {
  description = "Backend 시작 템플릿 ID"
  value       = module.asg_be.launch_template_id
}

# 인공지능
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

# ============================================================================
# ElastiCache
# ============================================================================

output "elasticache_replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = module.elasticache.replication_group_id
}

output "elasticache_primary_endpoint" {
  description = "ElastiCache primary endpoint (host:port)"
  value       = module.elasticache.primary_endpoint
}

output "elasticache_primary_endpoint_address" {
  description = "ElastiCache primary endpoint address"
  value       = module.elasticache.primary_endpoint_address
}

output "elasticache_port" {
  description = "ElastiCache port"
  value       = module.elasticache.port
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = module.elasticache.security_group_id
}

# ============================================================================
# Mock Server Outputs
# ============================================================================

output "asg_mock_name" {
  description = "Mock ASG name"
  value       = module.asg_mock.asg_name
}

output "asg_mock_arn" {
  description = "Mock ASG ARN"
  value       = module.asg_mock.asg_arn
}

output "asg_mock_launch_template_id" {
  description = "Mock 시작 템플릿 ID"
  value       = module.asg_mock.launch_template_id
}

output "mock_bundle_s3_uri" {
  description = "Mock bundle S3 URI"
  value       = "s3://${aws_s3_object.mock_bundle.bucket}/${aws_s3_object.mock_bundle.key}"
}

output "mock_server_wiremock_url" {
  description = "WireMock URL via ALB"
  value       = "https://mock.devths.com"
}

output "mock_record_fqdn" {
  description = "Mock Route53 record FQDN"
  value       = aws_route53_record.mock.fqdn
}
