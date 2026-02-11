# ===================================
# EC2 역할
# ===================================

resource "aws_iam_role" "ec2" {
  name = "${title(var.project_name)}-EC2-${title(var.environment)}"

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
      Name = "${title(var.project_name)}-EC2-${title(var.environment)}"
    }
  )
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${title(var.project_name)}-EC2-${title(var.environment)}"
  role = aws_iam_role.ec2.name
}


# ===================================
# EC2 정책
# ===================================

# CloudWatch Metrics 정책
resource "aws_iam_policy" "cloudwatch_metrics" {
  name        = "${title(var.project_name)}-CloudWatch-Metrics-${title(var.environment)}"
  description = "CloudWatch PutMetricData policy for EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${title(var.project_name)}-CloudWatch-Metrics-${title(var.environment)}"
    }
  )
}

# EC2 Describe 정책 (Prometheus EC2 Service Discovery용)
resource "aws_iam_policy" "ec2_describe" {
  name        = "${title(var.project_name)}-EC2-Describe-${title(var.environment)}"
  description = "Tag policy for EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${title(var.project_name)}-EC2-Describe-${title(var.environment)}"
    }
  )
}

# ===================================
# EC2 인라인
# ===================================

# SSM Parameter Store 및 KMS 권한
resource "aws_iam_role_policy" "ec2_ssm_kms" {
  name = "${title(var.project_name)}-EC2-SSM-KMS-${title(var.environment)}"
  role = aws_iam_role.ec2.id

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
          "arn:aws:ssm:*:*:parameter/${var.environment_prefix}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          var.kms_key_arn
        ]
      }
    ]
  })
}

# S3 Artifact 버킷 권한
resource "aws_iam_role_policy" "ec2_s3_artifact" {
  name = "${title(var.project_name)}-EC2-S3-Artifact-${title(var.environment)}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = compact([
          var.artifact_bucket_arn,
          "${var.artifact_bucket_arn}/*",
          var.v1_artifact_bucket_arn != "" ? var.v1_artifact_bucket_arn : "",
          var.v1_artifact_bucket_arn != "" ? "${var.v1_artifact_bucket_arn}/*" : ""
        ])
      }
    ]
  })
}

# S3 Storage 버킷 권한 (presigned URL 생성용)
resource "aws_iam_role_policy" "ec2_s3_storage" {
  name = "${title(var.project_name)}-EC2-S3-Storage-${title(var.environment)}"
  role = aws_iam_role.ec2.id

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
          var.storage_bucket_arn,
          "${var.storage_bucket_arn}/*"
        ]
      }
    ]
  })
}

# SSM Session Manager 로그 권한 (CloudWatch Logs)
resource "aws_iam_role_policy" "ec2_ssm_logs" {
  name = "${title(var.project_name)}-EC2-SSM-Logs-${title(var.environment)}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.cloudwatch_log_group_arn}:*"
      }
    ]
  })
}

# SSM Session Manager 로그 권한 (S3)
resource "aws_iam_role_policy" "ec2_ssm_s3_logs" {
  name = "${title(var.project_name)}-EC2-SSM-S3-Logs-${title(var.environment)}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketCheck"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = var.ssm_log_bucket_arn
      },
      {
        Sid    = "SSMLogging"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "${var.ssm_log_bucket_arn}/*"
      }
    ]
  })
}


# ===================================
# EC2 정책 연결
# ===================================

# SSM 권한
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ECR 읽기 권한 매핑
resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# CodeDeploy 권한
resource "aws_iam_role_policy_attachment" "ec2_codedeploy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# CloudWatch Metrics 권한 연결
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_metrics" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.cloudwatch_metrics.arn
}

# CloudWatch Metrics 권한 연결
resource "aws_iam_role_policy_attachment" "ec2_ec2_describe" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_describe.arn
}
