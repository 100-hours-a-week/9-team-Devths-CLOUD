# ===================================
# SSM Session Manager 설정
# ===================================

# CloudWatch Log Group for SSM Sessions (Production)
# 참고: 암호화 비활성화 (비용 절감)
resource "aws_cloudwatch_log_group" "ssm_session_logs" {
  name              = "SSMSessionManagerLogGroup"
  retention_in_days = 14 # 2주 후 자동 삭제

  tags = merge(
    var.common_tags,
    {
      Name = "SSMSessionManagerLogGroup"
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
      s3BucketName                = aws_s3_bucket.devths_ssm_log.id
      s3KeyPrefix                 = "session-logs/"
      s3EncryptionEnabled         = false
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_session_logs.name
      cloudWatchEncryptionEnabled = false
      cloudWatchStreamingEnabled  = true
      idleSessionTimeout          = "20" # 20분 유휴 시 종료
      maxSessionDuration          = "60" # 최대 60분
      kmsKeyId                    = ""
      runAsEnabled                = false
      runAsDefaultUser            = ""
      shellProfile = {
        windows = ""
        linux   = "exec /bin/bash\nsudo su - ubuntu\ncd ~"
      }
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "SSM-SessionManagerRunShell"
    }
  )
}

# ===================================
# CloudWatch Monitoring & Alarms
# ===================================

# 모니터링 서버 Discord-Prod SNS 토픽 참조
data "aws_sns_topic" "discord" {
  name = "Discord"
}

# 운영용 서버 Discord-Prod SNS 토픽 참조
data "aws_sns_topic" "discord_prod" {
  name = "Discord-Prod"
}

# ===================================
# 위험한 명령어 감지
# ===================================

# CloudWatch Metric Filter - 위험한 명령어 실행 감지
resource "aws_cloudwatch_log_metric_filter" "dangerous_commands" {
  name           = "DangerousCommandCount"
  log_group_name = aws_cloudwatch_log_group.ssm_session_logs.name

  # 위험한 명령어 패턴 감지 (포괄적인 텍스트 매칭)
  # Patterns: rm -rf, rm -fr, chmod 777/666, mkfs, iptables -F, ufw disable, setenforce 0,
  #           wget/curl http, bash -i, nc -e, dd if=, /dev/tcp/, base64 -d, eval $(,
  #           systemctl stop, kill -9, userdel, sudo su
  pattern = "?\"rm -rf\" ?\"rm -fr\" ?\"chmod 777\" ?\"chmod 666\" ?\"mkfs\" ?\"iptables -F\" ?\"ufw disable\" ?\"setenforce 0\" ?\"wget http\" ?\"curl http\" ?\"bash -i\" ?\"nc -e\" ?\"dd if=\" ?\"/dev/tcp/\" ?\"base64 -d\" ?\"eval $(\" ?\"systemctl stop\" ?\"kill -9\" ?\"userdel\" ?\"sudo su\""

  metric_transformation {
    name          = "DangerousCommandCount"
    namespace     = "Security/Logs"
    value         = "1"
    default_value = 0
    unit          = "Count"
  }
}

# CloudWatch Alarm - 위험한 명령어 실행 시 즉시 알림
resource "aws_cloudwatch_metric_alarm" "dangerous_command_alert" {
  alarm_name          = "Alert-Dangerous-Keyword"
  alarm_description   = "[CRITICAL] Dangerous command detected in SSM session"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DangerousCommandCount"
  namespace           = "Security/Logs"
  period              = 60 # 1분
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [data.aws_sns_topic.discord.arn]

  tags = merge(
    var.common_tags,
    {
      Name     = "Alert-Dangerous-Keyword"
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

  alarm_actions = [data.aws_sns_topic.discord_prod.arn]

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

  alarm_actions = [data.aws_sns_topic.discord_prod.arn]

  tags = merge(
    var.common_tags,
    {
      Name     = "EBS-Under-20-Prod"
      Severity = "Medium"
      Type     = "Storage"
    }
  )
}
