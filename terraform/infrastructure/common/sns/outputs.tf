output "sns_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.name
}

output "lambda_function_arn" {
  description = "ARN of the Discord notifier Lambda function"
  value       = aws_lambda_function.discord_notifier.arn
}

output "lambda_function_name" {
  description = "Name of the Discord notifier Lambda function"
  value       = aws_lambda_function.discord_notifier.function_name
}
