# ============================================================================
# IAM (EC2 역할 및 CodeDeploy 역할)
# ============================================================================

# IAM 모듈
module "iam" {
  source = "../../modules/iam"

  project_name             = var.project_name
  environment              = var.environment
  environment_prefix       = "Dev"
  kms_key_arn              = module.ssm_parameters.kms_key_arn
  artifact_bucket_arn      = data.terraform_remote_state.s3.outputs.artifact_bucket_arn
  v1_artifact_bucket_arn   = "arn:aws:s3:::devths-v1-artifact-nonprod"
  storage_bucket_arn       = module.s3_storage.bucket_arn
  ssm_log_bucket_arn       = data.terraform_remote_state.ssm.outputs.ssm_log_bucket_arn
  cloudwatch_log_group_arn = data.terraform_remote_state.ssm.outputs.cloudwatch_log_group_arn
  common_tags              = var.common_tags

  depends_on = [module.ssm_parameters, module.s3_storage]
}
