# ===================================
# NAT Instance 역할
# ===================================

resource "aws_iam_role" "nat_instance" {
  name = "${title(var.project_name)}-NAT-Instance-${title(var.environment)}"

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
      Name = "${title(var.project_name)}-NAT-Instance-${title(var.environment)}"
    }
  )
}

resource "aws_iam_instance_profile" "nat_instance" {
  name = "${title(var.project_name)}-NAT-Instance-${title(var.environment)}"
  role = aws_iam_role.nat_instance.name
}


# ===================================
# NAT Instance 정책
# ===================================

# SSM Session Manager 로그 권한 (CloudWatch Logs)
resource "aws_iam_role_policy" "nat_ssm_logs" {
  name = "${title(var.project_name)}-NAT-SSM-Logs-${title(var.environment)}"
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
        Resource = "${var.cloudwatch_log_group_arn}:*"
      }
    ]
  })
}

# SSM Session Manager 로그 권한 (S3)
resource "aws_iam_role_policy" "nat_ssm_s3_logs" {
  name = "${title(var.project_name)}-NAT-SSM-S3-Logs-${title(var.environment)}"
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
# NAT Instance 정책 연결
# ===================================

# SSM 권한 (Session Manager 접속용)
resource "aws_iam_role_policy_attachment" "nat_ssm" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Metrics 권한 연결 (모니터링용)
resource "aws_iam_role_policy_attachment" "nat_cloudwatch_metrics" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = aws_iam_policy.cloudwatch_metrics.arn
}
