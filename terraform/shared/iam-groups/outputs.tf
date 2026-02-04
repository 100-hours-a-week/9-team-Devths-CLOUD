# IAM 그룹 출력
output "developers_fullstack_group_name" {
  description = "Name of the developers IAM group"
  value       = aws_iam_group.developers.name
}

output "developers_fullstack_group_arn" {
  description = "ARN of the developers IAM group"
  value       = aws_iam_group.developers.arn
}

# IAM 정책 ARN 출력
output "s3_storage_readonly_policy_arn" {
  description = "ARN of S3 Storage Read-Only policy"
  value       = aws_iam_policy.s3_storage_readonly.arn
}

output "ssm_session_manager_policy_arn" {
  description = "ARN of SSM Session Manager policy"
  value       = aws_iam_policy.ssm_session_manager.arn
}

output "mfa_management_policy_arn" {
  description = "ARN of MFA Management policy"
  value       = aws_iam_policy.mfa_management.arn
}

output "password_and_mfa_enforcement_policy_arn" {
  description = "ARN of Password and MFA Enforcement policy"
  value       = aws_iam_policy.password_and_mfa_enforcement.arn
}

output "access_key_management_policy_arn" {
  description = "ARN of Access Key Management policy"
  value       = aws_iam_policy.access_key_management.arn
}
