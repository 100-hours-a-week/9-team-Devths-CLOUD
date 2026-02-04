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

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
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

# CORS 설정 (optional)
resource "aws_s3_bucket_cors_configuration" "this" {
  count = var.cors_rules != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# 퍼블릭 읽기 정책 (optional)
resource "aws_s3_bucket_policy" "public_read" {
  count = var.enable_public_read ? 1 : 0

  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.this.arn}/*",
          aws_s3_bucket.this.arn
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}
