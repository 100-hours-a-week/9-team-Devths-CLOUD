# ============================================================================
# CodeDeploy (Frontend, Backend, AI)
# ============================================================================
#
# CodeDeploy Application은 `terraform/shared/codedeploy-v2`에서 공통으로 생성합니다.
#
# ============================================================================

# CodeDeploy 모듈 - Frontend
module "codedeploy_fe" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-FE"
  deployment_group_name  = "Devths-V2-FE-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Frontend"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2_fe.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2_fe, module.iam]
}

# CodeDeploy 모듈 - Backend
module "codedeploy_be" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-BE"
  deployment_group_name  = "Devths-V2-BE-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Backend"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2_be.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2_be, module.iam]
}

# CodeDeploy 모듈 - AI
module "codedeploy_ai" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-AI"
  deployment_group_name  = "Devths-V2-AI-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Ai"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2_ai.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2_ai, module.iam]
}
