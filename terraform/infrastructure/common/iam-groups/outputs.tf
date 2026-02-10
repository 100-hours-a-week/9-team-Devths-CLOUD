# IAM 그룹 출력
output "developers_fullstack_group_name" {
  description = "Name of the developers IAM group"
  value       = aws_iam_group.developers.name
}

output "developers_fullstack_group_arn" {
  description = "ARN of the developers IAM group"
  value       = aws_iam_group.developers.arn
}

output "service_accounts_group_name" {
  description = "Name of the service-accounts IAM group"
  value       = aws_iam_group.service_accounts.name
}

output "service_accounts_group_arn" {
  description = "ARN of the service-accounts IAM group"
  value       = aws_iam_group.service_accounts.arn
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

# IAM 개발자 사용자 출력
output "developer_users" {
  description = "List of developer IAM users"
  value = {
    for key, user in aws_iam_user.developers : key => {
      name = user.name
      arn  = user.arn
    }
  }
}

# 개발자 초기 비밀번호 (sensitive)
output "developer_initial_passwords" {
  description = "Initial passwords for developer users - MUST be changed on first login"
  sensitive   = true
  value = {
    for key, profile in aws_iam_user_login_profile.developers : key => {
      password                = profile.password
      password_reset_required = profile.password_reset_required
    }
  }
}

# S3 서비스 계정 출력
output "s3_service_accounts" {
  description = "S3 service accounts for each environment"
  value = {
    for key, user in aws_iam_user.s3_service : key => {
      name = user.name
      arn  = user.arn
    }
  }
}

# GitHub Actions 서비스 계정 출력
output "github_actions_service_account" {
  description = "GitHub Actions service account"
  value = {
    name = data.aws_iam_user.github_actions.user_name
    arn  = data.aws_iam_user.github_actions.arn
  }
}
