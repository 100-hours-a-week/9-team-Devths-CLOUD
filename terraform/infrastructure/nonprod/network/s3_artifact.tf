# ============================================================================
# Code Deploy용 S3 버킷
# ============================================================================

module "s3_artifact" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-${var.infra_version}-artifact-${var.environment}"
  purpose            = "CodeDeploy artifacts for NonProd"
  versioning_enabled = true

  # 생명 주기 설정
  lifecycle_rules = [
    {
      id              = "delete_old_versions"
      status          = "Enabled"
      noncurrent_days = 90
      expiration_days = null
    },
    {
      id              = "delete_old_artifacts"
      status          = "Enabled"
      noncurrent_days = null
      expiration_days = 180
    }
  ]

  # 태그
  common_tags = var.common_tags
}
