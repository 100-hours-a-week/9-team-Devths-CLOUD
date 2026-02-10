# ===================================
# IAM 개발자 사용자 (Developer Users)
# ===================================

# 개발자 목록 정의
locals {
  developers = {
    yun = {
      name = "yun"
    }
    neon = {
      name = "neon"
    }
    estar = {
      name = "estar"
    }
  }
}

# Developer 사용자 생성
resource "aws_iam_user" "developers" {
  for_each = local.developers

  name = each.value.name
  path = "/developers/"

  tags = merge(
    var.common_tags,
    {
      Name = each.value.name
      Team = "Development"
    }
  )
}

# 콘솔 로그인 프로필 (초기 비밀번호 강제 변경)
resource "aws_iam_user_login_profile" "developers" {
  for_each = local.developers

  user                    = aws_iam_user.developers[each.key].name
  password_reset_required = true

  lifecycle {
    ignore_changes = [
      password_reset_required,
    ]
  }
}

# developers 그룹에 사용자 추가
resource "aws_iam_user_group_membership" "developers" {
  for_each = local.developers

  user = aws_iam_user.developers[each.key].name
  groups = [
    aws_iam_group.developers.name
  ]
}
