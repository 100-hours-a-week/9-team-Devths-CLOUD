# ============================================================================
# IAM
# ============================================================================

# KMS 키 조회
data "aws_kms_alias" "ssm_params" {
  name = "alias/ssm-params-prod"
}

# IAM 모듈
module "iam" {
  source = "../../../modules/iam"

  project_name             = var.project_name
  environment              = var.environment
  environment_prefix       = "Prod"
  kms_key_arn              = data.aws_kms_alias.ssm_params.target_key_arn
  v1_artifact_bucket_arn   = data.terraform_remote_state.network.outputs.artifact_bucket_arn
  artifact_bucket_arn      = data.terraform_remote_state.network.outputs.artifact_bucket_v2_arn
  storage_bucket_arn       = module.s3_storage.bucket_arn
  ssm_log_bucket_arn       = data.terraform_remote_state.ssm.outputs.ssm_log_bucket_arn
  cloudwatch_log_group_arn = data.terraform_remote_state.ssm.outputs.cloudwatch_log_group_arn
  common_tags              = var.common_tags

  # 의존성
  depends_on = [module.s3_storage]
}
