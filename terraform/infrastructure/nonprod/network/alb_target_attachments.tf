# ============================================================================
# ALB 타겟 그룹에 인스턴스 등록 기준
# ============================================================================

# ============================================================================
# 개발용
# ============================================================================

data "aws_instances" "dev_fe" {
  filter {
    name   = "tag:Service"
    values = ["Frontend"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["dev"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "dev_be" {
  filter {
    name   = "tag:Service"
    values = ["Backend"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["dev"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "dev_ai" {
  filter {
    name   = "tag:Service"
    values = ["Ai"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["dev"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "dev_monitoring" {
  filter {
    name   = "tag:Type"
    values = ["Monitoring"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["dev"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# ============================================================================
# 스테이징용
# ============================================================================

data "aws_instances" "stg_fe" {
  filter {
    name   = "tag:Service"
    values = ["Frontend"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["staging"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "stg_be" {
  filter {
    name   = "tag:Service"
    values = ["Backend"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["staging"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "stg_ai" {
  filter {
    name   = "tag:Service"
    values = ["Ai"]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.infra_version]
  }

  filter {
    name   = "tag:Environment"
    values = ["staging"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# ============================================================================
# Dev Target Group Attachments
# ============================================================================

resource "aws_lb_target_group_attachment" "dev_fe" {
  count            = length(data.aws_instances.dev_fe.ids)
  target_group_arn = aws_lb_target_group.dev_fe.arn
  target_id        = data.aws_instances.dev_fe.ids[count.index]
  port             = 3000
}

resource "aws_lb_target_group_attachment" "dev_be" {
  count            = length(data.aws_instances.dev_be.ids)
  target_group_arn = aws_lb_target_group.dev_be.arn
  target_id        = data.aws_instances.dev_be.ids[count.index]
  port             = 8080
}

resource "aws_lb_target_group_attachment" "dev_ai" {
  count            = length(data.aws_instances.dev_ai.ids)
  target_group_arn = aws_lb_target_group.dev_ai.arn
  target_id        = data.aws_instances.dev_ai.ids[count.index]
  port             = 8000
}

resource "aws_lb_target_group_attachment" "nonprod_grafana" {
  count            = length(data.aws_instances.dev_monitoring.ids)
  target_group_arn = aws_lb_target_group.nonprod_grafana.arn
  target_id        = data.aws_instances.dev_monitoring.ids[count.index]
  port             = 3000
}

# ============================================================================
# Stg Target Group Attachments
# ============================================================================

resource "aws_lb_target_group_attachment" "stg_fe" {
  count            = length(data.aws_instances.stg_fe.ids)
  target_group_arn = aws_lb_target_group.stg_fe.arn
  target_id        = data.aws_instances.stg_fe.ids[count.index]
  port             = 3000
}

resource "aws_lb_target_group_attachment" "stg_be" {
  count            = length(data.aws_instances.stg_be.ids)
  target_group_arn = aws_lb_target_group.stg_be.arn
  target_id        = data.aws_instances.stg_be.ids[count.index]
  port             = 8080
}

resource "aws_lb_target_group_attachment" "stg_ai" {
  count            = length(data.aws_instances.stg_ai.ids)
  target_group_arn = aws_lb_target_group.stg_ai.arn
  target_id        = data.aws_instances.stg_ai.ids[count.index]
  port             = 8000
}
