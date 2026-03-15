# ============================================================================
# Code Deploy용 S3 Artifact 버킷
# ============================================================================

# S3 모듈 - V1 Artifact 버킷 (기존 운영 유지)
module "s3_artifact" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-v1-artifact-${var.environment}"
  purpose            = "CodeDeploy artifacts v1"
  versioning_enabled = true

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

  common_tags = var.common_tags
}

# S3 모듈 - V2 Artifact 버킷 (신규 배포용)
module "s3_artifact_v2" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-${var.infra_version}-artifact-${var.environment}"
  purpose            = "CodeDeploy artifacts v2"
  versioning_enabled = true

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

  common_tags = var.common_tags
}
