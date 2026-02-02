# ===================================
# VPC 정보
# ===================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.devths_prod.id
}

# ===================================
# EC2 인스턴스 정보
# ===================================

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.devths_prod_app.id
}

output "ec2_public_ip" {
  description = "EC2 Public IP (Elastic IP)"
  value       = aws_eip.devths_prod_app_eip.public_ip
}

output "ec2_private_ip" {
  description = "EC2 Private IP"
  value       = aws_instance.devths_prod_app.private_ip
}

output "ec2_name_tag" {
  description = "EC2 Name Tag"
  value       = aws_instance.devths_prod_app.tags["Name"]
}

# ===================================
# S3 버킷 정보
# ===================================

output "s3_bucket_name" {
  description = "S3 Bucket Name for deployment artifacts"
  value       = aws_s3_bucket.devths_prod_deploy.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.devths_prod_deploy.arn
}

# ===================================
# CodeDeploy 정보
# ===================================

output "codedeploy_fe_deployment_group" {
  description = "Frontend CodeDeploy Deployment Group Name"
  value       = aws_codedeploy_deployment_group.fe_prod_group.deployment_group_name
}

output "codedeploy_be_deployment_group" {
  description = "Backend CodeDeploy Deployment Group Name"
  value       = aws_codedeploy_deployment_group.be_prod_group.deployment_group_name
}

output "codedeploy_ai_deployment_group" {
  description = "AI CodeDeploy Deployment Group Name"
  value       = aws_codedeploy_deployment_group.ai_prod_group.deployment_group_name
}

# ===================================
# IAM Role 정보
# ===================================

output "ec2_iam_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2_prod.arn
}

output "ec2_iam_role_name" {
  description = "EC2 IAM Role Name"
  value       = aws_iam_role.ec2_prod.name
}

output "codedeploy_iam_role_arn" {
  description = "CodeDeploy IAM Role ARN"
  value       = aws_iam_role.codedeploy_prod.arn
}

output "codedeploy_iam_role_name" {
  description = "CodeDeploy IAM Role Name"
  value       = aws_iam_role.codedeploy_prod.name
}

