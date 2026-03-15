# ============================================================================
# 시작 템플릿
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

  user_data = local.launch_template_user_data

  tag_specifications {
    resource_type = "instance"

    # 태그
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

    # 태그
    tags = merge(
      var.common_tags,
      {
        Name = "${var.asg_name}-volume"
      }
    )
  }

  # 태그
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
