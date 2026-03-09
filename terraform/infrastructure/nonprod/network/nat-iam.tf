# ============================================================================
# NAT Instance IAM 역할 (vpc-nonprod-v2 전용)
# ============================================================================
#
# NAT Instance에 필요한 최소 권한만 부여:
# - SSM Session Manager (디버깅용 접속)
# - CloudWatch Logs (모니터링)
#
# ============================================================================

# SSM 로그 설정 참조
data "terraform_remote_state" "ssm" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "common/ssm/terraform.tfstate"
    region = var.tf_state_region
  }
}

# NAT Instance IAM 역할
resource "aws_iam_role" "nat_instance" {
  name = "${title(var.project_name)}-NAT-Instance-NonProd"

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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${title(var.project_name)}-NAT-Instance-NonProd"
    }
  )
}

# NAT Instance 인스턴스 프로파일
resource "aws_iam_instance_profile" "nat_instance" {
  name = "${title(var.project_name)}-NAT-Instance-NonProd"
  role = aws_iam_role.nat_instance.name
}

# CloudWatch Metrics 정책
resource "aws_iam_policy" "nat_cloudwatch_metrics" {
  name        = "${title(var.project_name)}-NAT-CloudWatch-Metrics-NonProd"
  description = "CloudWatch PutMetricData policy for NAT instance"

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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${title(var.project_name)}-NAT-CloudWatch-Metrics-NonProd"
    }
  )
}

# SSM Session Manager 로그 권한 (CloudWatch Logs)
resource "aws_iam_role_policy" "nat_ssm_logs" {
  name = "${title(var.project_name)}-NAT-SSM-Logs-NonProd"
  role = aws_iam_role.nat_instance.id

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
        Resource = "${data.terraform_remote_state.ssm.outputs.cloudwatch_log_group_arn}:*"
      }
    ]
  })
}

# SSM Session Manager 로그 권한 (S3)
resource "aws_iam_role_policy" "nat_ssm_s3_logs" {
  name = "${title(var.project_name)}-NAT-SSM-S3-Logs-NonProd"
  role = aws_iam_role.nat_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketCheck"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = data.terraform_remote_state.ssm.outputs.ssm_log_bucket_arn
      },
      {
        Sid    = "SSMLogging"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "${data.terraform_remote_state.ssm.outputs.ssm_log_bucket_arn}/*"
      }
    ]
  })
}

# SSM 권한 (Session Manager 접속용)
resource "aws_iam_role_policy_attachment" "nat_ssm" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Metrics 권한 연결
resource "aws_iam_role_policy_attachment" "nat_cloudwatch_metrics" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = aws_iam_policy.nat_cloudwatch_metrics.arn
}
