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

# IAM 개발자 사용자 출력
output "developer_users" {
  description = "List of developer IAM users"
  value = {
    yun = {
      name = aws_iam_user.yun.name
      arn  = aws_iam_user.yun.arn
    }
    neon = {
      name = aws_iam_user.neon.name
      arn  = aws_iam_user.neon.arn
    }
    estar = {
      name = aws_iam_user.estar.name
      arn  = aws_iam_user.estar.arn
    }
  }
}

# S3 서비스 계정 출력
output "s3_service_accounts" {
  description = "S3 service accounts for each environment"
  value = {
    dev = {
      name = aws_iam_user.s3_service_dev.name
      arn  = aws_iam_user.s3_service_dev.arn
    }
    staging = {
      name = aws_iam_user.s3_service_staging.name
      arn  = aws_iam_user.s3_service_staging.arn
    }
    prod = {
      name = aws_iam_user.s3_service_prod.name
      arn  = aws_iam_user.s3_service_prod.arn
    }
  }
}
