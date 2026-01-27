# ===================================
# EC2 IAM Role
# ===================================

# EC2 인스턴스 IAM Role
resource "aws_iam_role" "ec2_prod" {
  name = "Devths-EC2-Prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "Devths-EC2-Prod"
    }
  )
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_prod" {
  name = "Devths-EC2-Prod"
  role = aws_iam_role.ec2_prod.name
}

# AWS 관리형 정책 - SSM 접근
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# AWS 관리형 정책 - CodeDeploy
resource "aws_iam_role_policy_attachment" "ec2_codedeploy" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# S3 아티팩트 접근하는 역할
resource "aws_iam_policy" "s3_artifact_access" {
  name        = "S3-Access-Devths-artifact-prod"
  description = "Access to CodeDeploy artifact S3 bucket"

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

resource "aws_iam_role_policy_attachment" "ec2_s3_artifact" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.s3_artifact_access.arn
}

# Parameter Store 접근
resource "aws_iam_policy" "ec2_parameter_store" {
  name        = "EC2-ParameterStore-Prod"
  description = "Access to Parameter Store for application configuration"

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

resource "aws_iam_role_policy_attachment" "ec2_parameter_store" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.ec2_parameter_store.arn
}

# SSM 로그 S3 저장
resource "aws_iam_policy" "ec2_log_s3" {
  name        = "EC2-LogS3"
  description = "Allow SSM to write logs to S3"

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

resource "aws_iam_role_policy_attachment" "ec2_log_s3" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.ec2_log_s3.arn
}

# SSM Audit Logging
resource "aws_iam_policy" "ec2_audit_ssm" {
  name        = "EC2-Audit-SSM"
  description = "SSM session audit logging to CloudWatch"

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

resource "aws_iam_role_policy_attachment" "ec2_audit_ssm" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.ec2_audit_ssm.arn
}

# ===================================
# CodeDeploy IAM Role
# ===================================

# CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_prod" {
  name = "Devths-CodeDeploy-Prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "Devths-CodeDeploy-Prod"
    }
  )
}

# AWS 관리형 정책 - CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_managed" {
  role       = aws_iam_role.codedeploy_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRole"
}

# S3 아티팩트 접근 (CodeDeploy도 같은 정책 사용)
resource "aws_iam_role_policy_attachment" "codedeploy_s3_artifact" {
  role       = aws_iam_role.codedeploy_prod.name
  policy_arn = aws_iam_policy.s3_artifact_access.arn
}
