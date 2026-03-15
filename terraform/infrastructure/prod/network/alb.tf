# ============================================================================
# ALB
# ============================================================================

# ALB 생성
resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.infra_version}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.alb_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  # Prod는 삭제 보호 활성화
  enable_deletion_protection       = true
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-alb"
    }
  )
}
