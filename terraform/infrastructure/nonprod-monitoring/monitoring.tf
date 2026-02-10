# ============================================================================
# Monitoring Server
# ============================================================================

# 모니터링 EC2 서버 모듈
module "monitoring" {
  source = "../../modules/monitoring"

  instance_name             = "${var.project_name}-v2-monitoring-${var.environment}"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  vpc_id                    = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr                  = data.aws_vpc.nonprod.cidr_block
  iam_instance_profile_name = data.aws_iam_instance_profile.ec2_profile.name
  environment               = var.environment
  domain_name               = var.domain_name
  monitoring_domain         = "monitoring.dev.${var.domain_name}"
  prometheus_retention      = "30d"
  server_label              = "개발 모니터링 서버"
  grafana_admin_password    = var.grafana_admin_password
  root_volume_size          = var.root_volume_size

  # 모니터링 대상 IP 주소
  target_dev_ip     = data.terraform_remote_state.dev.outputs.ec2_private_ip
  target_staging_ip = data.terraform_remote_state.staging.outputs.ec2_private_ip

  common_tags = merge(
    var.common_tags,
    {
      Version = "v2"
    }
  )
}
