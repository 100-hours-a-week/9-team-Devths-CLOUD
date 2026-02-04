terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ===================================
# IAM 그룹
# ===================================

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/"
}

resource "aws_iam_group" "service_accounts" {
  name = "service-accounts"
  path = "/"
}

# ===================================
# 외부 IAM 사용자 참조
# ===================================

# GitHub Actions IAM 사용자 (shared/github-actions에서 생성됨)
data "aws_iam_user" "github_actions" {
  user_name = var.github_actions_user_name
}

# ===================================
# IAM 사용자
# ===================================

# Developer 사용자 생성
resource "aws_iam_user" "yun" {
  name = "yun"
  path = "/developers/"

  tags = merge(
    var.common_tags,
    {
      Name = "yun"
      Team = "Development"
    }
  )
}

resource "aws_iam_user" "neon" {
  name = "neon"
  path = "/developers/"

  tags = merge(
    var.common_tags,
    {
      Name = "neon"
      Team = "Development"
    }
  )
}

resource "aws_iam_user" "estar" {
  name = "estar"
  path = "/developers/"

  tags = merge(
    var.common_tags,
    {
      Name = "estar"
      Team = "Development"
    }
  )
}

# developers 그룹에 사용자 추가
resource "aws_iam_user_group_membership" "yun_developers" {
  user = aws_iam_user.yun.name
  groups = [
    aws_iam_group.developers.name
  ]
}

resource "aws_iam_user_group_membership" "neon_developers" {
  user = aws_iam_user.neon.name
  groups = [
    aws_iam_group.developers.name
  ]
}

resource "aws_iam_user_group_membership" "estar_developers" {
  user = aws_iam_user.estar.name
  groups = [
    aws_iam_group.developers.name
  ]
}

# ===================================
# IAM 정책
# ===================================

# 1. S3 Storage 버킷 읽기 전용 정책
resource "aws_iam_policy" "s3_storage_readonly" {
  name        = "S3-Storage-ReadOnly"
  description = "Read-only access to storage S3 buckets (dev, staging, prod)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-storage-dev",
          "arn:aws:s3:::${var.project_name}-storage-dev/*",
          "arn:aws:s3:::${var.project_name}-storage-staging",
          "arn:aws:s3:::${var.project_name}-storage-staging/*",
          "arn:aws:s3:::${var.project_name}-storage-prod",
          "arn:aws:s3:::${var.project_name}-storage-prod/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# 2. SSM Session Manager 접근 정책
resource "aws_iam_policy" "ssm_session_manager" {
  name        = "SSM-Session-Manager-Access"
  description = "Allows access to SSM Session Manager for EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:DescribeInstanceProperties",
          "ssm:GetConnectionStatus",
          "ssm:DescribeSessions",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# 3. MFA 관리 정책
resource "aws_iam_policy" "mfa_management" {
  name        = "MFA-Management"
  description = "Allows users to manage their own MFA devices"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListActions"
        Effect = "Allow"
        Action = [
          "iam:ListVirtualMFADevices",
          "iam:ListUsers"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageAnyMFAInAccount"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:mfa/*"
      },
      {
        Sid    = "AllowManageAndGetOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:EnableMFADevice",
          "iam:DeactivateMFADevice",
          "iam:ResyncMFADevice",
          "iam:GetUser",
          "iam:GetMFADevice"
        ]
        Resource = [
          "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
          "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# 4. 비밀번호 변경 및 MFA 강제 정책
resource "aws_iam_policy" "password_and_mfa_enforcement" {
  name        = "MFA-Force-Enforcement"
  description = "Allows password management and enforces MFA for all actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:ListMFADevices",
          "iam:GetAccountPasswordPolicy",
          "iam:GetAccountSummary"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowChangeOwnPasswordsOnFirstLogin"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowChangeOwnPasswordsAfterMFAEnabled"
        Effect = "Allow"
        Action = [
          "iam:GetLoginProfile",
          "iam:UpdateLoginProfile"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnVirtualMFADevice"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::*:mfa/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnUserMFA"
        Effect = "Allow"
        Action = [
          "iam:DeactivateMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid      = "DenyAllExceptListedIfNoMFA"
        Effect   = "Deny"
        NotAction = [
          "iam:ListUsers",
          "iam:ChangePassword",
          "iam:GetUser",
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:DeactivateMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# 5. Access Key 관리 정책
resource "aws_iam_policy" "access_key_management" {
  name        = "Access-Key-Management"
  description = "Allows users to manage their own access keys"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey",
          "iam:DeleteAccessKey",
          "iam:GetAccessKeyLastUsed",
          "iam:ListUserTags",
          "iam:ListServiceSpecificCredentials",
          "iam:ListSSHPublicKeys",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })

  tags = var.common_tags
}

# ===================================
# developers 정책을 그룹에 연결
# ===================================

resource "aws_iam_group_policy_attachment" "developers_s3_storage" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_storage_readonly.arn
}

resource "aws_iam_group_policy_attachment" "developers_ssm" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.ssm_session_manager.arn
}

resource "aws_iam_group_policy_attachment" "developers_mfa" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.mfa_management.arn
}

resource "aws_iam_group_policy_attachment" "developers_password_mfa_enforcement" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.password_and_mfa_enforcement.arn
}

resource "aws_iam_group_policy_attachment" "developers_access_key" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.access_key_management.arn
}

resource "aws_iam_group_policy_attachment" "developers_ec2_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# ===================================
# service-accounts 정책 연결
# ===================================

# 서비스 계정은 프로그래밍 방식 접근만 하므로 추가 정책 불필요
# 각 서비스 계정은 개별적으로 필요한 S3 정책만 보유

# ===================================
# S3 전용 서비스 계정 (로컬 개발용 - 환경별 분리)
# ===================================

# Dev 환경 S3 서비스 계정
resource "aws_iam_user" "s3_service_dev" {
  name = "devths-s3-service-dev"
  path = "/service-accounts/"

  tags = merge(
    var.common_tags,
    {
      Name        = "devths-s3-service-dev"
      Environment = "dev"
      Description = "Service account for S3 presigned URL generation - dev environment only"
    }
  )
}

resource "aws_iam_policy" "s3_storage_dev" {
  name        = "S3-Storage-Dev-FullAccess"
  description = "Full access to dev storage S3 bucket for presigned URL generation"

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
          "arn:aws:s3:::${var.project_name}-storage-dev",
          "arn:aws:s3:::${var.project_name}-storage-dev/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_user_policy_attachment" "s3_service_dev" {
  user       = aws_iam_user.s3_service_dev.name
  policy_arn = aws_iam_policy.s3_storage_dev.arn
}

resource "aws_iam_user_group_membership" "s3_service_dev" {
  user = aws_iam_user.s3_service_dev.name
  groups = [
    aws_iam_group.service_accounts.name
  ]
}

# Staging 환경 S3 서비스 계정
resource "aws_iam_user" "s3_service_staging" {
  name = "devths-s3-service-staging"
  path = "/service-accounts/"

  tags = merge(
    var.common_tags,
    {
      Name        = "devths-s3-service-staging"
      Environment = "staging"
      Description = "Service account for S3 presigned URL generation - staging environment only"
    }
  )
}

resource "aws_iam_policy" "s3_storage_staging" {
  name        = "S3-Storage-Staging-FullAccess"
  description = "Full access to staging storage S3 bucket for presigned URL generation"

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
          "arn:aws:s3:::${var.project_name}-storage-staging",
          "arn:aws:s3:::${var.project_name}-storage-staging/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_user_policy_attachment" "s3_service_staging" {
  user       = aws_iam_user.s3_service_staging.name
  policy_arn = aws_iam_policy.s3_storage_staging.arn
}

resource "aws_iam_user_group_membership" "s3_service_staging" {
  user = aws_iam_user.s3_service_staging.name
  groups = [
    aws_iam_group.service_accounts.name
  ]
}

# Production 환경 S3 서비스 계정
resource "aws_iam_user" "s3_service_prod" {
  name = "devths-s3-service-prod"
  path = "/service-accounts/"

  tags = merge(
    var.common_tags,
    {
      Name        = "devths-s3-service-prod"
      Environment = "prod"
      Description = "Service account for S3 presigned URL generation - production environment only"
    }
  )
}

resource "aws_iam_policy" "s3_storage_prod" {
  name        = "S3-Storage-Prod-FullAccess"
  description = "Full access to production storage S3 bucket for presigned URL generation"

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
          "arn:aws:s3:::${var.project_name}-storage-prod",
          "arn:aws:s3:::${var.project_name}-storage-prod/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_user_policy_attachment" "s3_service_prod" {
  user       = aws_iam_user.s3_service_prod.name
  policy_arn = aws_iam_policy.s3_storage_prod.arn
}

resource "aws_iam_user_group_membership" "s3_service_prod" {
  user = aws_iam_user.s3_service_prod.name
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
