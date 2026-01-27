# ===================================
# 커스텀 IAM 정책 정의
# ===================================

# 운영용 S3 아티팩트 접근
resource "aws_iam_policy" "s3_artifact_access" {
  name        = "S3-Access-Devths-artifact-prod"
  description = "S3-Access-Devths-artifact-prod"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3AccessPolicy"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.devths_prod_deploy.arn}/*"
        ]
      },
      {
        Sid    = "S3ListPolicy"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.devths_prod_deploy.arn
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "S3-Access-Devths-artifact-prod"
    }
  )
}

# Parameter Store 접근
resource "aws_iam_policy" "ec2_parameter_store" {
  name        = "EC2-ParameterStore-Prod"
  description = "EC2-ParameterStore-Prod"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:ap-northeast-2:015932244909:parameter/Prod/BE*",
          "arn:aws:ssm:ap-northeast-2:015932244909:parameter/Prod/AI*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:kms:ap-northeast-2:015932244909:key/a8cb4dd5-8a26-4335-a38c-7bcca70affb8"
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "EC2-ParameterStore-Prod"
    }
  )
}

# SSM Audit 로그 S3 저장
resource "aws_iam_policy" "ec2_log_s3" {
  name        = "EC2-LogS3"
  description = "EC2-LogS3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMLogging"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "arn:aws:s3:::devths-ssm-log/*"
      },
      {
        Sid    = "S3BucketCheck"
        Effect = "Allow"
        Action = "s3:GetBucketLocation"
        Resource = "arn:aws:s3:::devths-ssm-log"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "EC2-LogS3"
    }
  )
}

# SSM Audit Logging
resource "aws_iam_policy" "ec2_audit_ssm" {
  name        = "EC2-Audit-SSM"
  description = "EC2-Audit-SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "logs:DescribeLogGroups"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:ap-northeast-2:015932244909:log-group:SSMSessionMangerLogGroup:*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "EC2-Audit-SSM"
    }
  )
}


# GitHub Actions 사용자를 위한 CodeDeploy 정책
resource "aws_iam_policy" "github_actions_deploy" {
  name        = "GitHub-Actions-CodeDeploy-Policy"
  description = "Policy for GitHub Actions to deploy via CodeDeploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CodeDeployRead"
        Effect = "Allow"
        Action = [
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:ListApplications",
          "codedeploy:ListDeployments"
        ]
        Resource = "*"
      },
      {
        Sid    = "CodeDeployWrite"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource: [
        "arn:aws:codedeploy:ap-northeast-2:015932244909:application:Devhts-V1-FE",
        "arn:aws:codedeploy:ap-northeast-2:015932244909:deploymentgroup:Devhts-V1-FE/*",
        "arn:aws:codedeploy:ap-northeast-2:015932244909:application:Devhts-V1-BE",
        "arn:aws:codedeploy:ap-northeast-2:015932244909:deploymentgroup:Devhts-V1-BE/*",
        "arn:aws:codedeploy:ap-northeast-2:015932244909:application:Devhts-V1-AI",
        "arn:aws:codedeploy:ap-northeast-2:015932244909:deploymentgroup:Devhts-V1-AI/*"
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "GitHub-Actions-CodeDeploy-Policy"
    }
  )
}