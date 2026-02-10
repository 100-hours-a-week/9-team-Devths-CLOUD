output "github_actions_user_name" {
  description = "GitHub Actions IAM user name"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_user_arn" {
  description = "GitHub Actions IAM user ARN"
  value       = aws_iam_user.github_actions.arn
}

output "s3_artifacts_policy_arn" {
  description = "S3 artifacts policy ARN"
  value       = aws_iam_policy.s3_artifacts.arn
}

output "codedeploy_deployment_policy_arn" {
  description = "CodeDeploy deployment policy ARN"
  value       = aws_iam_policy.codedeploy_deployment.arn
}