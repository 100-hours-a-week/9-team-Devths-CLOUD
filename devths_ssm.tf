# ===================================
# SSM Session Manager 설정
# ===================================

# CloudWatch Log Group for SSM Sessions (Legacy)
resource "aws_cloudwatch_log_group" "ssm_session_logs_legacy" {
  name              = "SSMSessionMangerLogGroup"
  retention_in_days = 60 # 2개월 후 자동 삭제

  tags = merge(
    var.common_tags,
    {
      Name = "SSMSessionMangerLogGroup"
    }
  )
}

# CloudWatch Log Group for SSM Sessions (Production)
resource "aws_cloudwatch_log_group" "ssm_session_logs" {
  name              = "SSMSessionMangerLogGroup-Prod"
  retention_in_days = 60 # 2개월 후 자동 삭제

  tags = merge(
    var.common_tags,
    {
      Name = "SSMSessionMangerLogGroup-Prod"
    }
  )
}

# SSM Document - Session Manager 설정
resource "aws_ssm_document" "session_manager_prefs" {
  name            = "SSM-SessionManagerRunShell-V1-PROD"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = aws_s3_bucket.devths_ssm_log.id
      s3KeyPrefix                 = "session-logs/"
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_session_logs.name
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = true
      idleSessionTimeout          = "20" # 20분 유휴 시 종료
      maxSessionDuration          = "60" # 최대 60분
      runAsEnabled                = false
      runAsDefaultUser            = ""
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "SSM-SessionManagerRunShell-V1-PROD"
    }
  )
}

# ===================================
# CloudWatch Monitoring & Alarms
# ===================================

# 기존 Discord-Prod SNS 토픽 참조
data "aws_sns_topic" "discord" {
  name = "Discord-Prod"
}

# ===================================
# 위험한 명령어 감지
# ===================================

# CloudWatch Metric Filter - 위험한 명령어 실행 감지
resource "aws_cloudwatch_log_metric_filter" "dangerous_commands" {
  name           = "DangerousCommandCount-Prod"
  log_group_name = aws_cloudwatch_log_group.ssm_session_logs.name

  # 위험한 명령어 패턴 감지 (간단한 텍스트 매칭)
  pattern = "?\"rm -rf\" ?\"chmod 777\" ?\"mkfs\" ?\"iptables -F\" ?\"ufw disable\" ?\"bash -i\" ?\"nc -e\" ?\"base64 -d\" ?\"systemctl stop\" ?\"userdel\""

  metric_transformation {
    name          = "DangerousCommandCount-Prod"
    namespace     = "Security/Logs"
    value         = "1"
    default_value = 0
    unit          = "Count"
  }
}

# CloudWatch Alarm - 위험한 명령어 실행 시 즉시 알림
resource "aws_cloudwatch_metric_alarm" "dangerous_command_alert" {
  alarm_name          = "Alert-Dangerous-Keyword-Prod"
  alarm_description   = "[CRITICAL] Dangerous command detected in SSM session"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DangerousCommandCount-Prod"
  namespace           = "Security/Logs"
  period              = 60 # 1분
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [data.aws_sns_topic.discord.arn]

  tags = merge(
    var.common_tags,
    {
      Name     = "Alert-Dangerous-Keyword-Prod"
      Severity = "High"
      Type     = "Security"
    }
  )
}

# ===================================
# EC2 리소스 모니터링
# ===================================

# CloudWatch Alarm - CPU 사용률 60% 이상
resource "aws_cloudwatch_metric_alarm" "cpu_60_alert" {
  alarm_name          = "CPU-60-Alert-Prod"
  alarm_description   = "[WARNING] EC2 CPU utilization is above 60%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5분
  statistic           = "Average"
  threshold           = 60
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.devths_prod_app.id
  }

  alarm_actions = [data.aws_sns_topic.discord.arn]

  tags = merge(
    var.common_tags,
    {
      Name     = "CPU-60-Alert-Prod"
      Severity = "Medium"
      Type     = "Performance"
    }
  )
}

# CloudWatch Alarm - EBS 디스크 사용률 80% 이상 (남은 용량 20% 미만)
resource "aws_cloudwatch_metric_alarm" "ebs_under_20_alert" {
  alarm_name          = "EBS-Under-20-Prod"
  alarm_description   = "[WARNING] EBS disk usage is above 80% (less than 20% free)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300 # 5분
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.devths_prod_app.id
    path       = "/"
    device     = "nvme0n1p1"
    fstype     = "ext4"
  }

  alarm_actions = [data.aws_sns_topic.discord.arn]

  tags = merge(
    var.common_tags,
    {
      Name     = "EBS-Under-20-Prod"
      Severity = "Medium"
      Type     = "Storage"
    }
  )
}
