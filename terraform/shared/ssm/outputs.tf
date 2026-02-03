output "ssm_log_bucket_id" {
  description = "S3 bucket ID for SSM logs"
  value       = aws_s3_bucket.ssm_logs.id
}

output "ssm_log_bucket_arn" {
  description = "S3 bucket ARN for SSM logs"
  value       = aws_s3_bucket.ssm_logs.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for SSM sessions"
  value       = aws_cloudwatch_log_group.ssm_sessions.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.ssm_sessions.arn
}

output "session_manager_document_name" {
  description = "SSM Session Manager document name"
  value       = aws_ssm_document.session_manager_prefs.name
}

output "metric_filter_name" {
  description = "CloudWatch Metric Filter name for dangerous commands"
  value       = aws_cloudwatch_log_metric_filter.dangerous_commands.name
}

output "alarm_name" {
  description = "CloudWatch Alarm name for dangerous commands"
  value       = aws_cloudwatch_metric_alarm.dangerous_commands_alarm.alarm_name
}

output "alarm_arn" {
  description = "CloudWatch Alarm ARN for dangerous commands"
  value       = aws_cloudwatch_metric_alarm.dangerous_commands_alarm.arn
}
