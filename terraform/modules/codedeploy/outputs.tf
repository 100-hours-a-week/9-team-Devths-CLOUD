# 배포 그룹 Id
output "deployment_group_id" {
  description = "Deployment group ID"
  value       = aws_codedeploy_deployment_group.this.id
}

# 배포 그룹 이름
output "deployment_group_name" {
  description = "Deployment group name"
  value       = aws_codedeploy_deployment_group.this.deployment_group_name
}
