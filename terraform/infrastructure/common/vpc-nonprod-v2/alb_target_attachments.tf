# ============================================================================
# Target Group Attachments (태그 기반 자동 등록)
# ============================================================================

# EC2 인스턴스를 태그 기반으로 자동 등록하는 데이터 소스
# Service, Project, Version 태그로 v2 인스턴스만 필터링

data "aws_instances" "fe" {
  filter {
    name   = "tag:Service"
    values = ["Frontend"]
  }

  filter {
    name   = "tag:Project"
    values = ["devths"]
  }

  filter {
    name   = "tag:Version"
    values = ["v2"]
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
    values = ["devths"]
  }

  filter {
    name   = "tag:Version"
    values = ["v2"]
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
    values = ["devths"]
  }

  filter {
    name   = "tag:Version"
    values = ["v2"]
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
    values = ["devths"]
  }

  filter {
    name   = "tag:Version"
    values = ["v2"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Target Group Attachment - Frontend
resource "aws_lb_target_group_attachment" "fe" {
  count            = length(data.aws_instances.fe.ids)
  target_group_arn = aws_lb_target_group.fe.arn
  target_id        = data.aws_instances.fe.ids[count.index]
  port             = 3000
}

# Target Group Attachment - Backend
resource "aws_lb_target_group_attachment" "be" {
  count            = length(data.aws_instances.be.ids)
  target_group_arn = aws_lb_target_group.be.arn
  target_id        = data.aws_instances.be.ids[count.index]
  port             = 8080
}

# Target Group Attachment - AI
resource "aws_lb_target_group_attachment" "ai" {
  count            = length(data.aws_instances.ai.ids)
  target_group_arn = aws_lb_target_group.ai.arn
  target_id        = data.aws_instances.ai.ids[count.index]
  port             = 8000
}

# Target Group Attachment - Grafana
resource "aws_lb_target_group_attachment" "grafana" {
  count            = length(data.aws_instances.monitoring.ids)
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = data.aws_instances.monitoring.ids[count.index]
  port             = 3000
}
