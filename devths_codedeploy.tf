# ===================================
# CodeDeploy 배포 그룹
# ===================================
# 기존 AWS 콘솔의 CodeDeploy 애플리케이션을 사용
# 애플리케이션: Devhts-V1-FE, Devhts-V1-BE, Devhts-V1-AI

# Frontend 배포 그룹
resource "aws_codedeploy_deployment_group" "fe_prod_group" {
  app_name              = "Devhts-V1-FE"
  deployment_group_name = "Devths-V1-FE-Prod-Group"
  service_role_arn      = aws_iam_role.codedeploy_prod.arn

  # EC2 인스턴스 타겟팅 (태그 기반)
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Service"
      type  = "KEY_AND_VALUE"
      value = "Frontend"
    }

    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = "production"
    }
  }

  # 배포 설정
  deployment_config_name = var.deployment_config_name

  # 자동 롤백 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # 배포 스타일 설정
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  tags = merge(
    var.common_tags,
    {
      Name    = "Devths-V1-FE-Prod-Group"
      Service = "Frontend"
    }
  )
}

# Backend 배포 그룹
resource "aws_codedeploy_deployment_group" "be_prod_group" {
  app_name              = "Devhts-V1-BE"
  deployment_group_name = "Devths-V1-BE-Prod-Group"
  service_role_arn      = aws_iam_role.codedeploy_prod.arn

  # EC2 인스턴스 타겟팅 (태그 기반)
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Service"
      type  = "KEY_AND_VALUE"
      value = "Backend"
    }

    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = "production"
    }
  }

  # 배포 설정
  deployment_config_name = var.deployment_config_name

  # 자동 롤백 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # 배포 스타일 설정
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  tags = merge(
    var.common_tags,
    {
      Name    = "Devths-V1-BE-Prod-Group"
      Service = "Backend"
    }
  )
}

# AI 배포 그룹
resource "aws_codedeploy_deployment_group" "ai_prod_group" {
  app_name              = "Devhts-V1-AI"
  deployment_group_name = "Devths-V1-AI-Prod-Group"
  service_role_arn      = aws_iam_role.codedeploy_prod.arn

  # EC2 인스턴스 타겟팅 (태그 기반)
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Service"
      type  = "KEY_AND_VALUE"
      value = "AI"
    }

    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = "production"
    }
  }

  # 배포 설정
  deployment_config_name = var.deployment_config_name

  # 자동 롤백 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  # 배포 스타일 설정
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  tags = merge(
    var.common_tags,
    {
      Name    = "Devths-V1-AI-Prod-Group"
      Service = "AI"
    }
  )
}

# SNS Topic - 배포 알림용 (선택사항)
resource "aws_sns_topic" "codedeploy_notifications" {
  name = "devths-codedeploy-notifications"

  tags = merge(
    var.common_tags,
    {
      Name = "devths-codedeploy-notifications"
    }
  )
}
