# ============================================================================
# ALB
# ============================================================================

resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.infra_version}-nonprod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.alb_security_group_id]
  subnets            = [module.vpc.public_subnet_ids[0]] # ap-northeast-2a에 지정

  # 부가 설정
  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  # 태그
  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-nonprod-alb"
    }
  )
}
