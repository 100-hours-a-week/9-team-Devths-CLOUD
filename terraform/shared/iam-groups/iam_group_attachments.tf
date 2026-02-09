# ===================================
# IAM 그룹 정책 연결 (Group Policy Attachments)
# ===================================

# ===================================
# developers 그룹 정책 연결
# ===================================

# S3 Storage 읽기 전용 접근
resource "aws_iam_group_policy_attachment" "developers_s3_storage" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_storage_readonly.arn
}

# SSM Session Manager 접근
resource "aws_iam_group_policy_attachment" "developers_ssm" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.ssm_session_manager.arn
}

# MFA 관리
resource "aws_iam_group_policy_attachment" "developers_mfa" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.mfa_management.arn
}

# 비밀번호 및 MFA 강제
resource "aws_iam_group_policy_attachment" "developers_password_mfa_enforcement" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.password_and_mfa_enforcement.arn
}

# Access Key 관리
resource "aws_iam_group_policy_attachment" "developers_access_key" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.access_key_management.arn
}

# EC2 읽기 전용 접근 (AWS 관리형 정책)
resource "aws_iam_group_policy_attachment" "developers_ec2_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# ===================================
# service-accounts 그룹 정책 연결
# ===================================

# 서비스 계정은 프로그래밍 방식 접근만 하므로 추가 정책 불필요
# 각 서비스 계정은 개별적으로 필요한 S3 정책만 보유 (iam_service_accounts.tf 참조)
