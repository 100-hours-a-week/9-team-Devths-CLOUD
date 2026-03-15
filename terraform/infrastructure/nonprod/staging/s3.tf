# S3 모듈 - Storage 버킷
module "s3_storage" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-storage-${var.environment}"
  purpose            = "Staging storage"
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
        "https://stg.devths.com",
        "https://stg.api.devths.com",
        "https://stg.ai.devths.com"
      ]
      expose_headers  = ["Access-Control-Allow-Origin"]
      max_age_seconds = 3000
    }
  ]

  # 생명주기 규칙
  lifecycle_rules = null

  common_tags = var.common_tags
}
