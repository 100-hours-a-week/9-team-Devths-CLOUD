terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

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
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = var.cloudwatch_log_group_name
    }
  )
}

# SSM Document - Session Manager 설정
resource "aws_ssm_document" "session_manager_prefs" {
  name            = var.ssm_document_name
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
      Name = var.ssm_document_name
    }
  )
}

# CloudWatch Metric Filter - 위험한 명령어 실행 감지
resource "aws_cloudwatch_log_metric_filter" "dangerous_commands" {
  name           = "DangerousCommandCount"
  log_group_name = aws_cloudwatch_log_group.ssm_sessions.name

  # 위험한 명령어 패턴 감지
  pattern = "?\"rm -rf\" ?\"rm -fr\" ?\"chmod 777\" ?\"chmod 666\" ?\"mkfs\" ?\"iptables -F\" ?\"ufw disable\" ?\"setenforce 0\" ?\"wget http\" ?\"curl http\" ?\"bash -i\" ?\"nc -e\" ?\"dd if=\" ?\"/dev/tcp/\" ?\"base64 -d\" ?\"eval $(\" ?\"systemctl stop\" ?\"kill -9\" ?\"userdel\" ?\"sudo su\""

  metric_transformation {
    name          = "DangerousCommandCount"
    namespace     = "Security/Logs"
    value         = "1"
    default_value = 0
    unit          = "Count"
  }
}

# CloudWatch Alarm - 위험한 명령어 감지 시 알림
resource "aws_cloudwatch_metric_alarm" "dangerous_commands_alarm" {
  alarm_name          = "SSM-DangerousCommand-Detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DangerousCommandCount"
  namespace           = "Security/Logs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "SSM 세션에서 위험한 명령어가 실행되었습니다"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = merge(
    var.common_tags,
    {
      Name = "SSM-DangerousCommand-Alarm"
    }
  )
}