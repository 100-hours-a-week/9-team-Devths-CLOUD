# ============================================================================
# EC2 인스턴스 (Frontend, Backend, AI)
# ============================================================================

# EC2 모듈 - Frontend
module "ec2_fe" {
  source = "../../modules/ec2"

  instance_name             = "${var.project_name}-v2-${var.environment}-fe"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  security_group_id         = data.terraform_remote_state.vpc.outputs.alb_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  aws_region                = var.aws_region
  enable_eip                = var.enable_eip
  environment               = var.environment
  infra_version             = var.infra_version
  domain_name               = "devths.com"
  discord_webhook_url       = var.discord_webhook_url
  service_type              = "fe"

  common_tags = merge(var.common_tags, {
    Service = "Frontend"
  })

  depends_on = [module.iam]
}

# EC2 모듈 - Backend
module "ec2_be" {
  source = "../../modules/ec2"

  instance_name             = "${var.project_name}-v2-${var.environment}-be"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  security_group_id         = data.terraform_remote_state.vpc.outputs.alb_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  aws_region                = var.aws_region
  enable_eip                = var.enable_eip
  environment               = var.environment
  infra_version             = var.infra_version
  domain_name               = "devths.com"
  discord_webhook_url       = var.discord_webhook_url
  service_type              = "be"

  common_tags = merge(var.common_tags, {
    Service = "Backend"
  })

  depends_on = [module.iam]
}

# EC2 모듈 - Ai
module "ec2_ai" {
  source = "../../modules/ec2"

  instance_name             = "${var.project_name}-v2-${var.environment}-ai"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  security_group_id         = data.terraform_remote_state.vpc.outputs.alb_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  aws_region                = var.aws_region
  enable_eip                = var.enable_eip
  environment               = var.environment
  infra_version             = var.infra_version
  domain_name               = "devths.com"
  discord_webhook_url       = var.discord_webhook_url
  service_type              = "ai"

  common_tags = merge(var.common_tags, {
    Service = "Ai"
  })

  depends_on = [module.iam]
}
