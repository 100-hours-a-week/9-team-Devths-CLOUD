# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = var.app_name
  deployment_group_name = var.deployment_group_name
  service_role_arn      = var.service_role_arn

  # EC2 인스턴스 타겟팅 (Service + Environment + Version 태그 조합)
  # ASG에서 생성된 모든 인스턴스가 이 태그 조합을 가지면 자동으로 배포 대상이 됨
  # Version 태그로 v1/v2를 분리하여 배포 가능
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Service"
      type  = "KEY_AND_VALUE"
      value = var.service_name
    }

    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.environment
    }

    ec2_tag_filter {
      key   = "Version"
      type  = "KEY_AND_VALUE"
      value = var.infra_version
    }
  }

  # 배포 설정
  deployment_config_name = var.deployment_config_name

  # 자동 롤백 설정
  auto_rollback_configuration {
    enabled = var.auto_rollback_enabled
    events  = var.auto_rollback_events
  }

  # 배포 스타일 설정
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  tags = merge(
    var.common_tags,
    {
      Name    = var.deployment_group_name
      Service = var.service_name
    }
  )
}
