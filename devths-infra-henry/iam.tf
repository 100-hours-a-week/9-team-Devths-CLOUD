# -----------------------------------------------------------
# IAM Role 설정 (SSM 접속용 신분증)
# -----------------------------------------------------------

# (1) 역할 생성
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-ec2-ssm-role-${var.owner}"

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
}

# (2) 정책 연결: AWS가 관리하는 'SSMManagedInstanceCore' 정책을 위 역할에 붙임
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# (3) 인스턴스 프로파일: EC2에 끼울 수 있는 형태로 포장
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-ec2-ssm-profile-${var.owner}"
  role = aws_iam_role.ssm_role.name
}
