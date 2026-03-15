# ============================================================================
# K8s 워커 노드 ASG
# ============================================================================

module "k8s_worker_asg" {
  source = "../../../modules/asg"

  # Launch Template 설정
  launch_template_name      = "${var.project_name}-${var.infra_version}-${var.environment}-k8s-worker-lt"
  instance_type             = var.worker_instance_type
  key_name                  = var.key_name
  security_group_ids        = [local.use_network_managed_worker_sg ? local.network_k8s_worker_security_group_id : module.worker_security_group[0].security_group_id]
  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  # ASG 설정
  asg_name                  = "${var.project_name}-${var.infra_version}-${var.environment}-k8s-worker-asg"
  min_size                  = var.worker_asg_min_size
  max_size                  = var.worker_asg_max_size
  desired_capacity          = var.worker_asg_desired_capacity
  subnet_ids                = data.terraform_remote_state.network.outputs.private_subnet_ids
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = []

  # 환경 설정
  environment   = var.environment
  infra_version = var.infra_version
  service_type  = "k8s-worker"
  aws_region    = var.aws_region

  # 인스턴스 설정
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  # K8s 워커용 커스텀 User Data
  custom_user_data_base64 = base64gzip(
    templatefile("${path.module}/scripts/k8s_worker_user_data.sh", {
      cluster_name          = local.cluster_name
      kubernetes_version    = var.kubernetes_version
      node_name             = "${var.project_name}-${var.infra_version}-${var.environment}-k8s-worker"
      timezone              = var.timezone
      join_command_ssm_path = local.join_command_ssm_path
    })
  )

  # Auto Scaling 정책 활성화 (워커는 부하에 따라 자동 스케일링)
  enable_autoscaling = var.enable_worker_autoscaling

  # 공통 태그
  common_tags = merge(var.common_tags, {
    Name                                          = "${var.project_name}-${var.infra_version}-${var.environment}-k8s-worker"
    Cluster                                       = local.cluster_name
    Role                                          = "worker"
    Type                                          = "k8s-worker"
    Service                                       = "Kubernetes"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })

  depends_on = [module.iam]
}
