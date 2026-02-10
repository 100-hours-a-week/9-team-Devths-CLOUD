# ============================================================================
# CodeDeploy (Frontend, Backend, AI)
# ============================================================================
#
# CodeDeploy Application은 `terraform/shared/codedeploy-v2`에서 공통으로 생성합니다.
#
# ============================================================================

# CodeDeploy 모듈 - Frontend
# Service + Environment + Version 태그 조합으로 타겟팅
# ASG 확장 시 동일한 태그를 가진 모든 인스턴스가 배포 대상이 됨
module "codedeploy_fe" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-FE"
  deployment_group_name  = "Devths-V2-FE-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Frontend"
  environment            = var.environment
  infra_version          = var.infra_version
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2_fe, module.iam]
}

# CodeDeploy 모듈 - Backend
# Service + Environment + Version 태그 조합으로 타겟팅
# ASG 확장 시 동일한 태그를 가진 모든 인스턴스가 배포 대상이 됨
module "codedeploy_be" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-BE"
  deployment_group_name  = "Devths-V2-BE-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Backend"
  environment            = var.environment
  infra_version          = var.infra_version
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2_be, module.iam]
}

# CodeDeploy 모듈 - AI
# Service + Environment + Version 태그 조합으로 타겟팅
# ASG 확장 시 동일한 태그를 가진 모든 인스턴스가 배포 대상이 됨
module "codedeploy_ai" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-AI"
  deployment_group_name  = "Devths-V2-AI-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Ai"
  environment            = var.environment
  infra_version          = var.infra_version
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2_ai, module.iam]
}
