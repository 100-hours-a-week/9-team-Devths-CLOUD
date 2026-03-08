# ============================================================================
# Locals - 템플릿 파일 렌더링
# ============================================================================

locals {
  # Docker Compose 설정
  docker_compose_content = templatefile("${path.module}/scripts/templates/docker-compose.yml.tpl", {
    environment            = var.environment
    prometheus_retention   = var.prometheus_retention
    grafana_admin_password = var.grafana_admin_password
    monitoring_domain      = var.monitoring_domain
  })

  # Prometheus 설정
  prometheus_content = templatefile("${path.module}/scripts/templates/prometheus.yml.tpl", {
    environment = var.environment
    aws_region  = var.aws_region
  })

  # Infrastructure Alert Rules 설정 (환경별)
  infrastructure_alert_rules_content = var.environment == "nonprod" ? templatefile("${path.module}/scripts/templates/alert-rules-nonprod.yml.tpl", {}) : templatefile("${path.module}/scripts/templates/alert-rules-prod.yml.tpl", {})

  # Application Alert Rules 설정
  backend_alert_rules_content = templatefile("${path.module}/scripts/templates/alert-rules-backend.yml.tpl", {
    environment = var.environment
  })
  front_alert_rules_content = templatefile("${path.module}/scripts/templates/alert-rules-front.yml.tpl", {})

  # Loki 설정
  loki_content = templatefile("${path.module}/scripts/templates/loki-config.yml.tpl", {
    aws_region           = var.aws_region
    environment          = var.environment
    loki_s3_bucket_name  = var.loki_s3_bucket_name
    prometheus_retention = var.prometheus_retention
  })

  # Tempo 설정
  tempo_content = templatefile("${path.module}/scripts/templates/tempo-config.yml.tpl", {
    aws_region           = var.aws_region
    tempo_s3_bucket_name = var.tempo_s3_bucket_name
  })

  # Promtail 설정
  promtail_content = templatefile("${path.module}/scripts/templates/promtail-config.yml.tpl", {
    environment = var.environment
  })

  # Alertmanager 설정
  alertmanager_content = templatefile("${path.module}/scripts/templates/alertmanager.yml.tpl", {
    discord_webhook_nonprod = var.alertmanager_discord_webhook_nonprod
    discord_webhook_prod    = var.alertmanager_discord_webhook_prod
  })

  # Grafana Datasources 설정
  grafana_datasources_content = templatefile("${path.module}/scripts/templates/grafana-datasources.yml.tpl", {})
  grafana_dashboards_content  = templatefile("${path.module}/scripts/templates/grafana-dashboards.yml.tpl", {})
}

# ============================================================================
# EC2 인스턴스 (모니터링 서버)
# ============================================================================

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  iam_instance_profile   = var.iam_instance_profile_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
  }

  # user_data를 gzip으로 압축하여 16KB 제한 우회
  user_data_base64 = base64gzip(
    templatefile("${path.module}/scripts/monitoring_user_data.sh", {
      monitoring_domain                  = var.monitoring_domain
      environment                        = var.environment
      grafana_admin_password             = var.grafana_admin_password
      docker_compose_content             = local.docker_compose_content
      prometheus_content                 = local.prometheus_content
      infrastructure_alert_rules_content = local.infrastructure_alert_rules_content
      backend_alert_rules_content        = local.backend_alert_rules_content
      front_alert_rules_content          = local.front_alert_rules_content
      loki_content                       = local.loki_content
      tempo_content                      = local.tempo_content
      promtail_content                   = local.promtail_content
      alertmanager_content               = local.alertmanager_content
      grafana_datasources_content        = local.grafana_datasources_content
      grafana_dashboards_content         = local.grafana_dashboards_content
    })
  )

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
      Type = "Monitoring"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}
