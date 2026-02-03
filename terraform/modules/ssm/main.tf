# SSM Session Manager 로그용 S3 버킷
resource "aws_s3_bucket" "ssm_logs" {
  bucket = var.bucket_name

  tags = merge(
    var.common_tags,
    {
      Name    = var.bucket_name
      Purpose = "SSM Session logs"
    }
  )
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Logs 그룹 - SSM 세션 로그
resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "SSMSessionMangerLogGroup"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "SSMSessionMangerLogGroup"
    }
  )
}

# SSM Document - Session Manager 설정
resource "aws_ssm_document" "session_manager_prefs" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = aws_s3_bucket.ssm_logs.id
      s3KeyPrefix                 = "session-logs/"
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = var.cloudwatch_streaming_enabled
      idleSessionTimeout          = var.idle_session_timeout
      maxSessionDuration          = var.max_session_duration
      runAsEnabled                = false
      runAsDefaultUser            = ""
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "SSM-SessionManagerRunShell"
    }
  )
}

# SSM Session Manager preferences 설정
resource "aws_ssm_document" "session_preferences" {
  name            = "SSM-SessionManagerPreferences"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager Preferences"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = aws_s3_bucket.ssm_logs.id
      s3KeyPrefix                 = "session-logs/"
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = var.cloudwatch_streaming_enabled
      kmsKeyId                    = var.kms_key_id != null ? var.kms_key_id : ""
      runAsEnabled                = false
      runAsDefaultUser            = ""
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "SSM-SessionManagerPreferences"
    }
  )
}
