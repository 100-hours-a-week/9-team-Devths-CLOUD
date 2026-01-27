# EC2 인스턴스 IAM Role
resource "aws_iam_role" "devths_prod_ec2_role" {
  name = "devths_prod_ec2_role"

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

  tags = {
    Name = "devths_prod_ec2_role"
  }
}

# EC2가 S3에서 배포 아티팩트를 가져올 수 있는 권한
resource "aws_iam_role_policy" "devths_prod_ec2_s3_policy" {
  name = "devths_prod_ec2_s3_policy"
  role = aws_iam_role.devths_prod_ec2_role.id

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
          aws_s3_bucket.devths_prod_deploy.arn,
          "${aws_s3_bucket.devths_prod_deploy.arn}/*"
        ]
      }
    ]
  })
}

# CodeDeploy 에이전트가 필요한 권한
resource "aws_iam_role_policy_attachment" "devths_prod_ec2_codedeploy" {
  role       = aws_iam_role.devths_prod_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "devths_prod_ec2_profile" {
  name = "devths_prod_ec2_profile"
  role = aws_iam_role.devths_prod_ec2_role.name
}

# CodeDeploy Service Role
resource "aws_iam_role" "devths_prod_codedeploy_role" {
  name = "devths_prod_codedeploy_role"

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

  tags = {
    Name = "devths_prod_codedeploy_role"
  }
}

# CodeDeploy가 EC2와 Auto Scaling을 관리할 수 있는 권한
resource "aws_iam_role_policy_attachment" "devths_prod_codedeploy_policy" {
  role       = aws_iam_role.devths_prod_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRole"
}
