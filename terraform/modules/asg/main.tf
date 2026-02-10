# ============================================================================
# Local Variables
# ============================================================================

locals {
  # 환경별 prefix (dev., stg., 또는 빈 문자열)
  env_prefix = var.environment == "prod" ? "" : "${var.environment}."

  # 서버 레이블 (fail2ban 알림용)
  server_label = var.environment == "prod" ? "운영 서버" : var.environment == "stg" ? "스테이징 서버" : "개발 서버"

  # CloudWatch Agent 네임스페이스
  cloudwatch_namespace = var.environment == "prod" ? "CWAgent/Production" : var.environment == "stg" ? "CWAgent/Staging" : "CWAgent/Dev"

  # Service 이름 매핑 (CodeDeploy 태그와 일치시키기 위해)
  service_name_map = {
    "fe"  = "Frontend"
    "be"  = "Backend"
    "ai"  = "Ai"
    "all" = "All"
  }
  service_name = lookup(local.service_name_map, var.service_type, "Unknown")
}

# ============================================================================
# Launch Template
# ============================================================================

resource "aws_launch_template" "this" {
  name          = var.launch_template_name
  image_id      = data.aws_ami.ubuntu_22_04.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  vpc_security_group_ids = var.security_group_ids

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      iops                  = var.root_volume_type == "gp3" ? 3000 : null
      throughput            = var.root_volume_type == "gp3" ? 125 : null
      delete_on_termination = true
      encrypted             = true
    }
  }

  # user_data를 gzip으로 압축하여 16KB 제한 우회
  user_data = base64gzip(join("\n", [
    "#!/bin/bash",
    templatefile("${path.module}/scripts/user_data.sh", {
      env_prefix           = local.env_prefix
      domain_name          = var.domain_name
      environment          = var.environment
      server_label         = local.server_label
      discord_webhook_url  = var.discord_webhook_url
      cloudwatch_namespace = local.cloudwatch_namespace
      service_type         = var.service_type
    }),
    file("${path.module}/scripts/install_node_exporter.sh"),
    file("${path.module}/scripts/setup_logrotate.sh"),
  ]))

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
        Name    = "${var.asg_name}-instance"
        Service = local.service_name
        Version = var.infra_version
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.asg_name}-volume"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.launch_template_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Auto Scaling Group
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
  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = local.service_name
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
