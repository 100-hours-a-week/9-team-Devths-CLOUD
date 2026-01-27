# VPC 정보
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.devths_prod.id
}

# EC2 인스턴스 정보
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

# S3 버킷 정보
output "s3_bucket_name" {
  description = "S3 Bucket Name for deployment artifacts"
  value       = aws_s3_bucket.devths_prod_deploy.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.devths_prod_deploy.arn
}

# CodeDeploy 정보
output "codedeploy_app_name" {
  description = "CodeDeploy Application Name"
  value       = aws_codedeploy_app.devths_prod_app.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy Deployment Group Name"
  value       = aws_codedeploy_deployment_group.devths_prod_deployment_group.deployment_group_name
}

# IAM Role 정보
output "ec2_iam_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.devths_prod_ec2_role.arn
}

output "codedeploy_iam_role_arn" {
  description = "CodeDeploy IAM Role ARN"
  value       = aws_iam_role.devths_prod_codedeploy_role.arn
}

# SSH 접속 명령어 (참고용)
output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_eip.devths_prod_app_eip.public_ip}"
}

# CodeDeploy 배포 명령어 예시 (참고용)
output "deploy_command_example" {
  description = "Example CodeDeploy deployment command"
  value       = <<-EOT
    aws deploy create-deployment \
      --application-name ${aws_codedeploy_app.devths_prod_app.name} \
      --deployment-group-name ${aws_codedeploy_deployment_group.devths_prod_deployment_group.deployment_group_name} \
      --s3-location bucket=${aws_s3_bucket.devths_prod_deploy.id},key=your-app.zip,bundleType=zip \
      --region ap-northeast-2
  EOT
}
