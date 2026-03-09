# ============================================================================
# ALB 타겟 그룹에 인스턴스 등록 기준
# ============================================================================


data "aws_instances" "fe" {
  filter {
    name   = "tag:Service"
    values = ["Frontend"]
  }

  filter {
    name   = "tag:Project"
    values = var.project_name
  }

  filter {
    name   = "tag:Version"
    values = var.infra_version
  }

  filter {
    name   = "tag:Environment"
    values = var.environment
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "be" {
  filter {
    name   = "tag:Service"
    values = ["Backend"]
  }

  filter {
    name   = "tag:Project"
    values = var.project_name
  }

  filter {
    name   = "tag:Version"
    values = var.infra_version
  }

  filter {
    name   = "tag:Environment"
    values = var.environment
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "ai" {
  filter {
    name   = "tag:Service"
    values = ["Ai"]
  }

  filter {
    name   = "tag:Project"
    values = var.project_name
  }

  filter {
    name   = "tag:Version"
    values = var.infra_version
  }

  filter {
    name   = "tag:Environment"
    values = var.environment
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "monitoring" {
  filter {
    name   = "tag:Type"
    values = ["Monitoring"]
  }

  filter {
    name   = "tag:Project"
    values = var.project_name
  }

  filter {
    name   = "tag:Version"
    values = var.infra_version
  }

  filter {
    name   = "tag:Environment"
    values = var.environment
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# ============================================================================
# Prod Target Group Attachments
# ============================================================================

resource "aws_lb_target_group_attachment" "fe" {
  count            = length(data.aws_instances.fe.ids)
  target_group_arn = aws_lb_target_group.fe.arn
  target_id        = data.aws_instances.fe.ids[count.index]
  port             = 3000
}

resource "aws_lb_target_group_attachment" "be" {
  count            = length(data.aws_instances.be.ids)
  target_group_arn = aws_lb_target_group.be.arn
  target_id        = data.aws_instances.be.ids[count.index]
  port             = 8080
}

resource "aws_lb_target_group_attachment" "ai" {
  count            = length(data.aws_instances.ai.ids)
  target_group_arn = aws_lb_target_group.ai.arn
  target_id        = data.aws_instances.ai.ids[count.index]
  port             = 8000
}

resource "aws_lb_target_group_attachment" "monitoring" {
  count            = length(data.aws_instances.monitoring)
  target_group_arn = aws_lb_target_group.monitoring.arn
  target_id        = data.aws_instances.monitoring.ids[count.index]
  port             = 3000
}