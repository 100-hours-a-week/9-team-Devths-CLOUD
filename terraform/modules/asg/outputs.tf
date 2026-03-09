# ============================================================================
# 시작 템플릿 Outputs
# ============================================================================

output "launch_template_id" {
  description = "시작 템플릿 ID"
  value       = aws_launch_template.this.id
}

output "launch_template_name" {
  description = "시작 템플릿 name"
  value       = aws_launch_template.this.name
}

output "launch_template_latest_version" {
  description = "시작 템플릿 latest version"
  value       = aws_launch_template.this.latest_version
}

# ============================================================================
# Auto Scaling Group Outputs
# ============================================================================

output "asg_id" {
  description = "Auto Scaling Group ID"
  value       = aws_autoscaling_group.this.id
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.this.arn
}

output "asg_min_size" {
  description = "Auto Scaling Group minimum size"
  value       = aws_autoscaling_group.this.min_size
}

output "asg_max_size" {
  description = "Auto Scaling Group maximum size"
  value       = aws_autoscaling_group.this.max_size
}

output "asg_desired_capacity" {
  description = "Auto Scaling Group desired capacity"
  value       = aws_autoscaling_group.this.desired_capacity
}

# ============================================================================
# Auto Scaling Policy Outputs
# ============================================================================

output "cpu_tracking_policy_arn" {
  description = "ARN of the CPU target tracking scaling policy"
  value       = var.enable_autoscaling ? aws_autoscaling_policy.cpu_tracking[0].arn : null
}

output "scale_out_policy_arn" {
  description = "ARN of the scale out policy"
  value       = var.enable_autoscaling ? aws_autoscaling_policy.scale_out[0].arn : null
}

output "scale_in_policy_arn" {
  description = "ARN of the scale in policy"
  value       = var.enable_autoscaling ? aws_autoscaling_policy.scale_in[0].arn : null
}

# ============================================================================
# CloudWatch Alarm Outputs
# ============================================================================

output "cpu_high_alarm_arn" {
  description = "ARN of the CPU high CloudWatch alarm"
  value       = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.cpu_high[0].arn : null
}

output "cpu_low_alarm_arn" {
  description = "ARN of the CPU low CloudWatch alarm"
  value       = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.cpu_low[0].arn : null
}
