# CodeDeploy Application
resource "aws_codedeploy_app" "this" {
  name             = var.app_name
  compute_platform = "Server"

  tags = merge(
    var.common_tags,
    {
      Name    = var.app_name
      Service = var.service_name
    }
  )
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = var.deployment_group_name
  service_role_arn      = var.service_role_arn

  # EC2 인스턴스 타겟팅
  ec2_tag_set {
    ec2_tag_filter {
      key   = var.ec2_tag_key
      type  = "KEY_AND_VALUE"
      value = var.ec2_tag_value
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
