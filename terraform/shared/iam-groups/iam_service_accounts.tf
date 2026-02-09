# ===================================
# S3 전용 서비스 계정 (환경별 분리)
# ===================================
# 로컬 개발용 S3 presigned URL 생성을 위한 서비스 계정

locals {
  service_environments = {
    dev = {
      environment = "dev"
      description = "Service account for S3 presigned URL generation - dev environment only"
    }
    staging = {
      environment = "staging"
      description = "Service account for S3 presigned URL generation - staging environment only"
    }
    prod = {
      environment = "prod"
      description = "Service account for S3 presigned URL generation - production environment only"
    }
  }
}

# 환경별 S3 서비스 계정 생성
resource "aws_iam_user" "s3_service" {
  for_each = local.service_environments

  name = "${var.project_name}-s3-service-${each.key}"
  path = "/service-accounts/"

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-s3-service-${each.key}"
      Environment = each.value.environment
      Description = each.value.description
    }
  )
}

# 환경별 S3 Full Access 정책
resource "aws_iam_policy" "s3_storage_env" {
  for_each = local.service_environments

  name        = "S3-Storage-${title(each.key)}-FullAccess"
  description = "Full access to ${each.key} storage S3 bucket for presigned URL generation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-storage-${each.key}",
          "arn:aws:s3:::${var.project_name}-storage-${each.key}/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# 서비스 계정에 정책 연결
resource "aws_iam_user_policy_attachment" "s3_service" {
  for_each = local.service_environments

  user       = aws_iam_user.s3_service[each.key].name
  policy_arn = aws_iam_policy.s3_storage_env[each.key].arn
}

# 서비스 계정을 service-accounts 그룹에 추가
resource "aws_iam_user_group_membership" "s3_service" {
  for_each = local.service_environments

  user = aws_iam_user.s3_service[each.key].name
  groups = [
    aws_iam_group.service_accounts.name
  ]
}

# GitHub Actions 사용자를 service-accounts 그룹에 추가
resource "aws_iam_user_group_membership" "github_actions" {
  user = data.aws_iam_user.github_actions.user_name
  groups = [
    aws_iam_group.service_accounts.name
  ]
}
