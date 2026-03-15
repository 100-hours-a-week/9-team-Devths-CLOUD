# ==============================================================================
# Launch Template Outputs
# ==============================================================================

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

output "launch_template_name" {
  description = "Name of the launch template"
  value       = aws_launch_template.this.name
}

# ==============================================================================
# Auto Scaling Group Outputs
# ==============================================================================

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

# Aliases for backwards compatibility
output "asg_id" {
  description = "ID of the Auto Scaling Group (alias)"
  value       = aws_autoscaling_group.this.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group (alias)"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group (alias)"
  value       = aws_autoscaling_group.this.arn
}

output "autoscaling_group_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.min_size
}

output "autoscaling_group_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.max_size
}

output "autoscaling_group_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.desired_capacity
}

# ==============================================================================
# Auto Scaling Policy Outputs
# ==============================================================================

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = var.enable_autoscaling ? aws_autoscaling_policy.scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = var.enable_autoscaling ? aws_autoscaling_policy.scale_down[0].arn : null
}

# ==============================================================================
# CloudWatch Alarm Outputs
# ==============================================================================

output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU CloudWatch alarm"
  value       = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}

output "low_cpu_alarm_arn" {
  description = "ARN of the low CPU CloudWatch alarm"
  value       = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.low_cpu[0].arn : null
}
