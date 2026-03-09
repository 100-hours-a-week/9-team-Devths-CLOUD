# ============================================================================
# ASG 그룹 (프런트/백엔드/AI)
# ============================================================================

# ============================================================================
# 프런트엔드
# ============================================================================
module "asg_fe" {
  source = "../../../modules/asg"

  # 시작 템플릿 설정
  launch_template_name      = "${var.project_name}-v2-${var.environment}-fe-lt"
  instance_type             = var.fe_instance_type
  key_name                  = var.key_name
  security_group_ids        = [data.terraform_remote_state.vpc.outputs.fe_security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  # ASG 설정
  asg_name                  = "${var.project_name}-v2-${var.environment}-fe-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  subnet_ids                = [data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]] # 2a only for cost optimization
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.dev_fe_target_group_arn]

  # 환경 설정
  environment   = var.environment
  infra_version = var.infra_version
  service_type  = "fe"
  aws_region    = var.aws_region

  # 인스턴스 설정
  root_volume_size = var.asg_root_volume_size
  root_volume_type = var.asg_root_volume_type

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Frontend"
  })

  depends_on = [module.iam]
}

# ============================================================================
# 백엔드
# ============================================================================
module "asg_be" {
  source = "../../../modules/asg"

  # 시작 템플릿 설정
  launch_template_name      = "${var.project_name}-${var.infra_version}-${var.environment}-be-lt"
  instance_type             = var.be_instance_type
  key_name                  = var.key_name
  security_group_ids        = [data.terraform_remote_state.vpc.outputs.be_security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  # ASG 설정
  asg_name                  = "${var.project_name}-${var.infra_version}-${var.environment}-be-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  subnet_ids                = [data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]] # 2a only for cost optimization
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.dev_be_target_group_arn]

  # 환경 설정
  environment   = var.environment
  infra_version = var.infra_version
  service_type  = "be"
  aws_region    = var.aws_region

  # 인스턴스 설정
  root_volume_size = var.asg_root_volume_size
  root_volume_type = var.asg_root_volume_type

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Backend"
  })

  depends_on = [module.iam]
}

# ============================================================================
# 인공지능
# ============================================================================
module "asg_ai" {
  source = "../../../modules/asg"

  # 시작 템플릿 설정
  launch_template_name      = "${var.project_name}-${var.infra_version}-${var.environment}-ai-lt"
  instance_type             = var.ai_instance_type
  key_name                  = var.key_name
  security_group_ids        = [data.terraform_remote_state.vpc.outputs.ai_security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  # ASG 설정
  asg_name                  = "${var.project_name}-${var.infra_version}-${var.environment}-ai-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  subnet_ids                = [data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]] # 2a only for cost optimization
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.dev_ai_target_group_arn]

  # 환경 설정
  environment   = var.environment
  infra_version = var.infra_version
  service_type  = "ai"
  aws_region    = var.aws_region

  # 인스턴스 설정
  root_volume_size = var.asg_root_volume_size
  root_volume_type = var.asg_root_volume_type

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Ai"
  })

  depends_on = [module.iam]
}