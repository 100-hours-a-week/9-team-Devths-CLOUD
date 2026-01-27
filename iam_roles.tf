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

# EC2 역할에 연결할 AWS 관리형 정책
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_codedeploy" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# EC2 역할에 연결할 커스텀 정책
resource "aws_iam_role_policy_attachment" "ec2_s3_artifact" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.s3_artifact_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_parameter_store" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.ec2_parameter_store.arn
}

resource "aws_iam_role_policy_attachment" "ec2_log_s3" {
  role       = aws_iam_role.ec2_prod.name
  policy_arn = aws_iam_policy.ec2_log_s3.arn
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

# CodeDeploy 역할에 연결할 AWS 관리형 정책
resource "aws_iam_role_policy_attachment" "codedeploy_managed" {
  role       = aws_iam_role.codedeploy_prod.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeDeploy 역할에 연결할 아티팩트 S3 정책
resource "aws_iam_role_policy_attachment" "s3_artifact_access" {
  role       = aws_iam_role.codedeploy_prod.name
  policy_arn = aws_iam_policy.s3_artifact_access.arn
}


# CodeDeploy 역할에 연결할 커스텀 정책
resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.codedeploy_prod.name
  policy_arn = aws_iam_policy.s3_artifact_access.arn
}
