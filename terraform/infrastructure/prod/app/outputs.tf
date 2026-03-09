# ============================================================================
# S3
# ============================================================================

output "s3_artifact_bucket" {
  description = "S3 artifact bucket name (v2) - from network layer"
  value       = data.terraform_remote_state.network.outputs.artifact_bucket_v2_name
}

output "s3_artifact_bucket_arn" {
  description = "S3 artifact bucket ARN (v2) - from network layer"
  value       = data.terraform_remote_state.network.outputs.artifact_bucket_v2_arn
}

output "s3_artifact_bucket_v1" {
  description = "S3 artifact bucket name (v1) - from network layer"
  value       = data.terraform_remote_state.network.outputs.artifact_bucket_name
}

output "s3_artifact_bucket_arn_v1" {
  description = "S3 artifact bucket ARN (v1) - from network layer"
  value       = data.terraform_remote_state.network.outputs.artifact_bucket_arn
}

output "s3_storage_bucket" {
  description = "S3 storage bucket name"
  value       = module.s3_storage.bucket_name
}

output "s3_storage_bucket_arn" {
  description = "S3 storage bucket ARN"
  value       = module.s3_storage.bucket_arn
}

# ============================================================================
# IAM
# ============================================================================

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = module.iam.ec2_role_arn
}

output "ec2_iam_role_name" {
  description = "EC2 IAM role name"
  value       = module.iam.ec2_role_name
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = module.iam.ec2_instance_profile_name
}

output "codedeploy_iam_role_arn" {
  description = "CodeDeploy IAM role ARN"
  value       = module.iam.codedeploy_role_arn
}

# ============================================================================
# CodeDeploy Outputs
# ============================================================================

output "codedeploy_fe_group_v2" {
  description = "Frontend deployment group name"
  value       = module.codedeploy_fe_v2.deployment_group_name
}

output "codedeploy_be_group_v2" {
  description = "Backend deployment group name"
  value       = module.codedeploy_be_v2.deployment_group_name
}

output "codedeploy_ai_group_v2" {
  description = "AI deployment group name"
  value       = module.codedeploy_ai_v2.deployment_group_name
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
