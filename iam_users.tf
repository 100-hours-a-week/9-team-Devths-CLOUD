# ===================================
# IAM 사용자 정책 연결
# ===================================

# GitHub Actions 사용자 - 커스텀 CodeDeploy 정책
resource "aws_iam_user_policy_attachment" "github_actions_deploy" {
  user       = "github-Actions"  # 콘솔에 있는 사용자 이름
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}

# GitHub Actions 사용자 - 운영용 S3 아티팩트 접근 정책
resource "aws_iam_user_policy_attachment" "github_actions_s3" {
  user       = "github-Actions"  # 콘솔에 있는 사용자 이름
  policy_arn = aws_iam_policy.s3_artifact_access.arn
}