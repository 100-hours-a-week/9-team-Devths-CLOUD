# ============================================================================
# Tempo에서 사용할 S3 버킷
# ============================================================================

# Tempo 트레이싱 데이터 저장용 S3 버킷
module "s3_tempo" {
  source = "../../../modules/s3"

  bucket_name        = "${var.project_name}-${var.infra_version}-monitoring-tempo-${var.environment}"
  purpose            = "Tempo Tracing Storage"
  versioning_enabled = false

  lifecycle_rules = [
    {
      id              = "delete_old_artifacts"
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

moved {
  from = aws_s3_bucket.tempo
  to   = module.s3_tempo.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_versioning.tempo
  to   = module.s3_tempo.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.tempo
  to   = module.s3_tempo.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_public_access_block.tempo
  to   = module.s3_tempo.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.tempo
  to   = module.s3_tempo.aws_s3_bucket_lifecycle_configuration.this[0]
}
