# ============================================================================
# S3 (Storage 버킷 - 환경별로 분리)
# ============================================================================

# S3 모듈 - Storage 버킷 (환경별로 분리)
module "s3_storage" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-storage-${var.environment}"
  purpose            = "Development storage"
  versioning_enabled = true

  # 퍼블릭 읽기 활성화
  block_public_access = false
  enable_public_read  = true

  # CORS 설정
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE"]
      allowed_origins = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://dev.devths.com",
        "https://dev.api.devths.com",
        "https://dev.ai.devths.com"
      ]
      expose_headers  = ["Access-Control-Allow-Origin"]
      max_age_seconds = 3000
    }
  ]

  lifecycle_rules = [
    {
      id              = "delete_old_versions"
      status          = "Enabled"
      noncurrent_days = 30
      expiration_days = null
    },
    {
      id              = "delete_old_artifacts"
      status          = "Enabled"
      noncurrent_days = null
      expiration_days = 7
    }
  ]

  common_tags = var.common_tags
}
