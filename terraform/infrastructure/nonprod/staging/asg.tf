# ============================================================================
# ASG 그룹 (프런트/백엔드/AI)
# ============================================================================

# ============================================================================
# 프런트엔드
# ============================================================================
module "asg_fe" {
  source = "../../../modules/asg"

  # 시작 템플릿 설정
  launch_template_name      = "${var.project_name}-${var.infra_version}-${var.environment}-fe-lt"
  instance_type             = var.fe_instance_type
  key_name                  = var.key_name
  security_group_ids        = [data.terraform_remote_state.vpc.outputs.fe_security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  # ASG 설정
  asg_name                  = "${var.project_name}-${var.infra_version}-${var.environment}-fe-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  subnet_ids                = [data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]] # ap-northeast-2a
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.stg_fe_target_group_arn]

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

  # 스테이징 스케쥴링 (KST 22:00 = UTC 13:00 스케일다운, KST 13:00 = UTC 04:00 스케일업)
  enable_scheduled_scaling     = true
  schedule_scale_down_time     = "20 13 * * *" # UTC 13:00 (KST 22:00)
  schedule_scale_down_min_size = 0
  schedule_scale_down_max_size = 0
  schedule_scale_down_desired  = 0
  schedule_scale_up_time       = "0 4 * * *" # UTC 04:00 (KST 13:00)
  schedule_scale_up_min_size   = var.asg_min_size
  schedule_scale_up_max_size   = var.asg_max_size
  schedule_scale_up_desired    = var.asg_desired_capacity

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
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.stg_be_target_group_arn]

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

  # 스테이징 스케쥴링 (KST 22:00 = UTC 13:00 스케일다운, KST 13:00 = UTC 04:00 스케일업)
  enable_scheduled_scaling     = true
  schedule_scale_down_time     = "20 13 * * *" # UTC 13:00 (KST 22:00)
  schedule_scale_down_min_size = 0
  schedule_scale_down_max_size = 0
  schedule_scale_down_desired  = 0
  schedule_scale_up_time       = "0 4 * * *" # UTC 04:00 (KST 13:00)
  schedule_scale_up_min_size   = var.asg_min_size
  schedule_scale_up_max_size   = var.asg_max_size
  schedule_scale_up_desired    = var.asg_desired_capacity

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
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.stg_ai_target_group_arn]

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

  # 스테이징 스케쥴링 (KST 22:00 = UTC 13:00 스케일다운, KST 13:00 = UTC 04:00 스케일업)
  enable_scheduled_scaling     = true
  schedule_scale_down_time     = "20 13 * * *" # UTC 13:00 (KST 22:00)
  schedule_scale_down_min_size = 0
  schedule_scale_down_max_size = 0
  schedule_scale_down_desired  = 0
  schedule_scale_up_time       = "0 4 * * *" # UTC 04:00 (KST 13:00)
  schedule_scale_up_min_size   = var.asg_min_size
  schedule_scale_up_max_size   = var.asg_max_size
  schedule_scale_up_desired    = var.asg_desired_capacity

  depends_on = [module.iam]
}

# ============================================================================
# Mock서버
# ============================================================================
module "asg_mock" {
  source = "../../../modules/asg"

  # 시작 템플릿 설정
  launch_template_name      = "${var.project_name}-${var.infra_version}-${var.environment}-mock-lt"
  instance_type             = var.mock_instance_type
  key_name                  = var.key_name
  security_group_ids        = [data.terraform_remote_state.vpc.outputs.mock_security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  # ASG 설정
  asg_name                  = "${var.project_name}-${var.infra_version}-${var.environment}-mock-asg"
  min_size                  = var.mock_asg_min_size
  max_size                  = var.mock_asg_max_size
  desired_capacity          = var.mock_asg_desired_capacity
  subnet_ids                = [data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]]
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = [data.terraform_remote_state.vpc.outputs.stg_mock_target_group_arn]

  # 환경 설정
  environment   = var.environment
  infra_version = var.infra_version
  service_type  = "mock"
  aws_region    = var.aws_region

  # 인스턴스 설정
  root_volume_size = var.mock_root_volume_size
  root_volume_type = var.mock_root_volume_type

  # Mock 서버 user_data 주입
  custom_user_data_base64 = base64gzip(
    replace(
      replace(
        file("${path.module}/scripts/mock_server_user_data.sh"),
        "__MOCK_BUNDLE_S3_URI__",
        "s3://${aws_s3_object.mock_bundle.bucket}/${aws_s3_object.mock_bundle.key}"
      ),
      "__AWS_REGION__",
      var.aws_region
    )
  )

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Mock"
  })

  # Mock은 고정 1대로 운용
  enable_autoscaling = false

  depends_on = [module.iam, aws_s3_object.mock_bundle]
}
