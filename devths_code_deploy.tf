# CodeDeploy Application
resource "aws_codedeploy_app" "devths_prod_app" {
  name             = "devths_prod_app"
  compute_platform = "Server"

  tags = {
    Name        = "devths_prod_app"
    Environment = "production"
  }
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "devths_prod_deployment_group" {
  app_name              = aws_codedeploy_app.devths_prod_app.name
  deployment_group_name = "devths_prod_deployment_group"
  service_role_arn      = aws_iam_role.devths_prod_codedeploy_role.arn

  # EC2 인스턴스 타겟팅 (태그 기반)
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "devths_prod_app"
    }

    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = "production"
    }
  }

  # 배포 설정 - 한 번에 하나씩 배포 (OneAtATime)
  deployment_config_name = "CodeDeployDefault.OneAtATime"

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

  # 로드 밸런서 설정 (선택사항 - ALB 사용 시)
  # load_balancer_info {
  #   target_group_info {
  #     name = aws_lb_target_group.devths_prod_tg.name
  #   }
  # }

  tags = {
    Name        = "devths_prod_deployment_group"
    Environment = "production"
  }
}

# SNS Topic - 배포 알림용 (선택사항)
resource "aws_sns_topic" "devths_prod_codedeploy_notifications" {
  name = "devths_prod_codedeploy_notifications"

  tags = {
    Name        = "devths_prod_codedeploy_notifications"
    Environment = "production"
  }
}

# CodeDeploy 트리거 - 배포 상태 알림 (선택사항)
# resource "aws_codedeploy_deployment_group" "devths_prod_deployment_group" {
#   ...
#   trigger_configuration {
#     trigger_events     = ["DeploymentStart", "DeploymentSuccess", "DeploymentFailure"]
#     trigger_name       = "devths_prod_deployment_trigger"
#     trigger_target_arn = aws_sns_topic.devths_prod_codedeploy_notifications.arn
#   }
# }
