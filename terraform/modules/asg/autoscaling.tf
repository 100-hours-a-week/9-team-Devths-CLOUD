# ============================================================================
# ASG
# ============================================================================

resource "aws_autoscaling_group" "this" {
  name                      = var.asg_name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # 인스턴스 교체 시 최소 용량 유지
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # ASG 태그 (인스턴스에 전파)
  dynamic "tag" {
    for_each = local.asg_propagated_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# ASG 정책
# ============================================================================

# Target Tracking Scaling Policy - CPU 기반
resource "aws_autoscaling_policy" "cpu_tracking" {
  count                  = var.enable_autoscaling ? 1 : 0
  name                   = "${var.asg_name}-cpu-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
  }
}

# Scale Out Policy (추가 제어용)
resource "aws_autoscaling_policy" "scale_out" {
  count                  = var.enable_autoscaling ? 1 : 0
  name                   = "${var.asg_name}-scale-out-policy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

# Scale In Policy (추가 제어용)
resource "aws_autoscaling_policy" "scale_in" {
  count                  = var.enable_autoscaling ? 1 : 0
  name                   = "${var.asg_name}-scale-in-policy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# ============================================================================
# CloudWatch Alarms
# ============================================================================

# CPU High Alarm (70% 초과 시 Scale Out)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_autoscaling ? 1 : 0
  alarm_name          = "${var.asg_name}-cpu-high"
  alarm_description   = "Triggers scale out when CPU exceeds ${var.scale_out_cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_out_cpu_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_out[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.asg_name}-cpu-high-alarm"
    }
  )
}

# CPU Low Alarm (30% 이하 시 Scale In)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.enable_autoscaling ? 1 : 0
  alarm_name          = "${var.asg_name}-cpu-low"
  alarm_description   = "Triggers scale in when CPU falls below ${var.scale_in_cpu_threshold}%"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_in_cpu_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_in[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.asg_name}-cpu-low-alarm"
    }
  )
}

# ============================================================================
# Scheduled Scaling Actions
# ============================================================================

# Scale Down Action (예: 밤 10시 - UTC 13:00)
resource "aws_autoscaling_schedule" "scale_down" {
  count                  = var.enable_scheduled_scaling ? 1 : 0
  scheduled_action_name  = "${var.asg_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.this.name
  recurrence             = var.schedule_scale_down_time
  min_size               = var.schedule_scale_down_min_size
  max_size               = var.schedule_scale_down_max_size
  desired_capacity       = var.schedule_scale_down_desired
}

# Scale Up Action (예: 오후 1시 - UTC 04:00)
resource "aws_autoscaling_schedule" "scale_up" {
  count                  = var.enable_scheduled_scaling ? 1 : 0
  scheduled_action_name  = "${var.asg_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.this.name
  recurrence             = var.schedule_scale_up_time
  min_size               = var.schedule_scale_up_min_size
  max_size               = var.schedule_scale_up_max_size
  desired_capacity       = var.schedule_scale_up_desired
}
