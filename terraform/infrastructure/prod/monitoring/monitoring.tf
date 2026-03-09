# ============================================================================
# Monitoring Server
# ============================================================================

# 모니터링 EC2 서버 모듈
module "monitoring" {
  source = "../../../modules/monitoring"

  project_name                         = var.project_name
  instance_name                        = "${var.project_name}-${var.infra_version}-${var.environment}-monitoring"
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  subnet_id                            = data.terraform_remote_state.prod.outputs.private_subnet_ids[0]
  vpc_id                               = data.terraform_remote_state.prod.outputs.vpc_id
  vpc_cidr                             = data.aws_vpc.prod.cidr_block
  alb_security_group_id                = data.aws_security_group.alb.id
  iam_instance_profile_name            = data.aws_iam_instance_profile.ec2_profile.name
  environment                          = var.environment
  domain_name                          = var.domain_name
  monitoring_domain                    = "monitoring.${var.domain_name}"
  prometheus_retention                 = "90d"
  server_label                         = "운영 모니터링 서버"
  grafana_admin_password               = var.grafana_admin_password
  alertmanager_discord_webhook_nonprod = var.alertmanager_discord_webhook_nonprod
  alertmanager_discord_webhook_prod    = var.alertmanager_discord_webhook_prod
  tempo_s3_bucket_name                 = var.tempo_s3_bucket_name
  loki_s3_bucket_name                  = var.loki_s3_bucket_name
  root_volume_size                     = var.root_volume_size
  aws_region                           = var.aws_region

  # 태그
  common_tags = merge(
    var.common_tags
  )
}
