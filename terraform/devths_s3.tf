# S3 버킷 - CodeDeploy 배포 아티팩트 저장용
resource "aws_s3_bucket" "devths_prod_deploy" {
  bucket = "devths-artifact-prod"

  tags = {
    Name        = "devths-artifact-prod"
    Environment = "production"
    Purpose     = "CodeDeploy artifacts"
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "devths_prod_deploy_public_access" {
  bucket = aws_s3_bucket.devths_prod_deploy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 버저닝 설정
resource "aws_s3_bucket_versioning" "devths_prod_deploy_versioning" {
  bucket = aws_s3_bucket.devths_prod_deploy.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "devths_prod_deploy_encryption" {
  bucket = aws_s3_bucket.devths_prod_deploy.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 라이프사이클 정책 - 오래된 아티팩트 자동 삭제
resource "aws_s3_bucket_lifecycle_configuration" "devths_prod_deploy_lifecycle" {
  bucket = aws_s3_bucket.devths_prod_deploy.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "delete_old_artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 180
    }
  }
}

# ===================================
# S3 버킷 - SSM Session Manager 로그 저장용
# ===================================

# SSM 로그 버킷
resource "aws_s3_bucket" "devths_ssm_log" {
  bucket = "devths-ssm-log"

  tags = {
    Name    = "devths-ssm-log"
    Purpose = "SSM Session Manager logs"
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "devths_ssm_log_public_access" {
  bucket = aws_s3_bucket.devths_ssm_log.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "devths_ssm_log_encryption" {
  bucket = aws_s3_bucket.devths_ssm_log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 라이프사이클 정책 - 60일 후 자동 삭제
resource "aws_s3_bucket_lifecycle_configuration" "devths_ssm_log_lifecycle" {
  bucket = aws_s3_bucket.devths_ssm_log.id

  rule {
    id     = "delete_old_ssm_logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 60
    }
  }
}
