# 현재 AWS 계정 ID 조회
data "aws_caller_identity" "current" {}

# 현재 리전 조회 (기존 var.aws_region 대신 사용 가능하지만, 혼용 방지를 위해 필요시 사용)
data "aws_region" "current" {}
