# ============================================================================
# S3 Storage 버킷
# ============================================================================

module "s3_storage" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-storage-${var.environment}"
  purpose            = "Production storage"
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
        "https://www.devths.com",
        "https://devths.com",
        "https://api.devths.com",
        "https://ai.devths.com"
      ]
      expose_headers  = ["Access-Control-Allow-Origin"]
      max_age_seconds = 3000
    }
  ]

  lifecycle_rules = null

  common_tags = var.common_tags
}
