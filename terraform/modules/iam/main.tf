# ===================================
# EC2 IAM Role
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

# SSM 권한
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CodeDeploy 권한
resource "aws_iam_role_policy_attachment" "ec2_codedeploy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# SSM Parameter Store 및 KMS 권한
resource "aws_iam_role_policy" "ec2_ssm_kms" {
  count = var.kms_key_arn != null && var.environment_prefix != null ? 1 : 0
  name  = "${title(var.project_name)}-EC2-SSM-KMS-${title(var.environment)}"
  role  = aws_iam_role.ec2.id

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

# ===================================
# CodeDeploy IAM Role
# ===================================

resource "aws_iam_role" "codedeploy" {
  name = "${title(var.project_name)}-CodeDeploy-${title(var.environment)}"

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
      Name = "${title(var.project_name)}-CodeDeploy-${title(var.environment)}"
    }
  )
}

# CodeDeploy 권한
resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
