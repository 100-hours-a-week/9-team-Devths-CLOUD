# 테라폼 설정
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 테라폼 설정 - 프로바이더
provider "aws" {
  region = var.aws_region
}

# ===================================
# IAM 유저
# ===================================

# IAM 유저 생성
resource "aws_iam_user" "github_actions" {
  name = var.github_actions_user_name
  path = "/service-accounts/"

  tags = merge(
    var.common_tags,
    {
      Name    = var.github_actions_user_name
      Purpose = "GitHub Actions CI/CD"
    }
  )
}

# ===================================
# S3 아티팩트 정책 연결
# ===================================

resource "aws_iam_policy" "s3_artifacts" {
  name        = "${var.project_name}-S3-Artifacts"
  description = "Allow access to all S3 artifact buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-v1-artifact-*",
          "arn:aws:s3:::${var.project_name}-v1-artifact-*/*",
          "arn:aws:s3:::${var.project_name}-v2-artifact-*",
          "arn:aws:s3:::${var.project_name}-v2-artifact-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-S3-Artifacts"
    }
  )
}

# ===================================
# CodeDeploy 관련 정책
# ===================================

resource "aws_iam_policy" "codedeploy_deployment" {
  name        = "${var.project_name}-CodeDeploy-Deployment"
  description = "Allow CodeDeploy deployment operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:ListDeployments",
          "codedeploy:ListApplicationRevisions",
          "codedeploy:GetApplication",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeploymentInstances",
          "codedeploy:GetDeploymentInstance"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-CodeDeploy-Deployment"
    }
  )
}

# ===================================
# ECR 관련 정책
# ===================================

resource "aws_iam_policy" "ecr_push_policy" {
  name        = "${var.project_name}-ECR-Push-Policy"
  description = "Allow pushing images to all devths/* repositories"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 1. 로그인 권한 (항상 필요)
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        # 2. 푸시 권한 (와일드카드 사용)
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        # devths/ 폴더 아래에 있는 모든 리포지토리를 허용
        Resource = "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/devths/*"
      }
    ]
  })
}

# ===================================
# 정책 연결하기
# ===================================

resource "aws_iam_user_policy_attachment" "github_actions_s3" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.s3_artifacts.arn
}

resource "aws_iam_user_policy_attachment" "github_actions_codedeploy" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.codedeploy_deployment.arn
}

resource "aws_iam_user_policy_attachment" "github_actions_ecr" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}
