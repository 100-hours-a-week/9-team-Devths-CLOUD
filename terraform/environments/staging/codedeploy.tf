# CodeDeploy Application은 `terraform/shared/codedeploy-v2`에서 공통으로 생성합니다.
# CodeDeploy 모듈 - Frontend
module "codedeploy_fe" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-FE"
  deployment_group_name  = "Devths-V2-FE-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Frontend"
  environment            = var.environment
  infra_version          = "v1"
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}

# CodeDeploy 모듈 - Backend
module "codedeploy_be" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-BE"
  deployment_group_name  = "Devths-V2-BE-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Backend"
  environment            = var.environment
  infra_version          = "v1"
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}

# CodeDeploy 모듈 - AI
module "codedeploy_ai" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-AI"
  deployment_group_name  = "Devths-V2-AI-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Ai"
  environment            = var.environment
  infra_version          = "v1"
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}
