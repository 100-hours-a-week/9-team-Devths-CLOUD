# ============================================================================
# SSM Parameter Store
# ============================================================================

# SSM Parameter Store 모듈
module "ssm_parameters" {
  source = "../../modules/ssm_parameters"

  environment_prefix  = "Dev"
  be_parameter_values = var.be_parameter_values
  ai_parameter_values = var.ai_parameter_values
  common_tags         = var.common_tags
}
