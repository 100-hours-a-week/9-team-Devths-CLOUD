# EC2
output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_role_name" {
  description = "EC2 IAM role name"
  value       = aws_iam_role.ec2.name
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "cloudwatch_metrics_policy_arn" {
  description = "CloudWatch metrics policy ARN"
  value       = aws_iam_policy.cloudwatch_metrics.arn
}

output "cloudwatch_metrics_policy_name" {
  description = "CloudWatch metrics policy name"
  value       = aws_iam_policy.cloudwatch_metrics.name
}

# CodeDeploy
output "codedeploy_role_arn" {
  description = "CodeDeploy IAM role ARN"
  value       = aws_iam_role.codedeploy.arn
}

output "codedeploy_role_name" {
  description = "CodeDeploy IAM role name"
  value       = aws_iam_role.codedeploy.name
}
