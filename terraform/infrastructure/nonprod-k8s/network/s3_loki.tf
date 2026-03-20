# ============================================================================
# Loki에서 사용할 S3 버킷
# ============================================================================

# Loki 로그 데이터 저장용 S3 버킷
module "s3_loki" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-${var.infra_version}-monitoring-loki-${var.environment}"
  purpose            = "Loki Log Storage"
  versioning_enabled = false

  lifecycle_rules = [
    {
      id              = "delete_old_logs"
      status          = "Enabled"
      noncurrent_days = null
      expiration_days = 30
    },
    {
      id              = "delete_old_versions"
      status          = "Enabled"
      noncurrent_days = 7
      expiration_days = null
    }
  ]

  common_tags = var.common_tags
}
