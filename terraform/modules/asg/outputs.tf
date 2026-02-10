# ============================================================================
# Launch Template Outputs
# ============================================================================

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.this.id
}

output "launch_template_name" {
  description = "Launch Template name"
  value       = aws_launch_template.this.name
}

output "launch_template_latest_version" {
  description = "Launch Template latest version"
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
