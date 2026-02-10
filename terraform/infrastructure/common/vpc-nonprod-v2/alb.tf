# ============================================================================
# Application Load Balancer
# ============================================================================

resource "aws_lb" "this" {
  name               = "${var.project_name}-v2-nonprod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.alb_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-nonprod-alb"
    }
  )
}
