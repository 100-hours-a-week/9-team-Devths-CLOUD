# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = var.app_name
  deployment_group_name = var.deployment_group_name
  service_role_arn      = var.service_role_arn

  # ASG 타겟팅 (ASG로 생성된 모든 인스턴스가 자동으로 배포 대상)
  autoscaling_groups = var.asg_name != "" ? [var.asg_name] : null

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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = var.deployment_group_name
      Service = var.service_name
    }
  )
}
