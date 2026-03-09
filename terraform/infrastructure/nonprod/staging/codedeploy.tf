

# ============================================================================
# 프런트엔드
# ============================================================================
module "codedeploy_fe" {
  source = "../../../modules/codedeploy"

  app_name               = "Devths-FE"
  deployment_group_name  = "Devths-${var.infra_version}-FE-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  asg_name               = module.asg_fe.asg_name
  service_name           = "Frontend"
  environment            = var.environment
  infra_version          = var.infra_version
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.asg_fe, module.iam]
}

# ============================================================================
# 백엔드
# ============================================================================
module "codedeploy_be" {
  source = "../../../modules/codedeploy"

  app_name               = "Devths-BE"
  deployment_group_name  = "Devths-${var.infra_version}-BE-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  asg_name               = module.asg_be.asg_name
  service_name           = "Backend"
  environment            = var.environment
  infra_version          = var.infra_version
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.asg_be, module.iam]
}

# ============================================================================
# 인공지능
# ============================================================================
module "codedeploy_ai" {
  source = "../../../modules/codedeploy"

  app_name               = "Devths-AI"
  deployment_group_name  = "Devths-${var.infra_version}-AI-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  asg_name               = module.asg_ai.asg_name
  service_name           = "Ai"
  environment            = var.environment
  infra_version          = var.infra_version
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.asg_ai, module.iam]
}
