# ============================================================================
# Monitoring EC2 (Prometheus + Grafana + Loki + Tempo + Alertmanager)
# ============================================================================

module "monitoring" {
  source = "../../../modules/monitoring"

  project_name              = var.project_name
  infra_version             = var.infra_version
  instance_name             = "${var.project_name}-${var.infra_version}-${var.environment}-monitoring"
  instance_type             = var.monitoring_instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.network.outputs.private_subnet_ids[var.private_subnet_index]
  vpc_id                    = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                  = data.terraform_remote_state.network.outputs.vpc_cidr
  alb_security_group_id     = data.terraform_remote_state.network.outputs.alb_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  environment               = var.environment
  domain_name               = var.domain_name
  monitoring_domain         = var.monitoring_domain
  prometheus_retention      = "30d"
  server_label              = "K8s 모니터링 서버"
  grafana_admin_password    = var.grafana_admin_password
  root_volume_size          = 50
  aws_region                = var.aws_region

  # S3 버킷 (network 스테이트에서 참조)
  loki_s3_bucket_name  = try(data.terraform_remote_state.network.outputs.loki_bucket_name, "")
  tempo_s3_bucket_name = try(data.terraform_remote_state.network.outputs.tempo_bucket_name, "")

  # K8s in-cluster NodePort URLs (마스터 노드 IP 고정)
  k8s_loki_nodeport_url  = var.k8s_loki_nodeport_url
  k8s_tempo_nodeport_url = var.k8s_tempo_nodeport_url

  # Alertmanager Discord 웹훅
  alertmanager_discord_webhook_nonprod = var.alertmanager_discord_webhook_nonprod

  common_tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.infra_version}-${var.environment}-monitoring"
    Type = "Monitoring"
  })

  depends_on = [module.iam]
}
