# S3 버킷
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    var.common_tags,
    {
      Name    = var.bucket_name
      Purpose = var.purpose
    }
  )
}

# 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 버저닝 설정
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 라이프사이클 정책 (optional)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.lifecycle_rules != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {}

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_days
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}
