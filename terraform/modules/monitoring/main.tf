# 최신 Ubuntu 22.04
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 환경별 도메인 설정을 위한 로컬 변수
locals {
  # 모니터링 도메인 (nonprod: monitoring.dev.devths.com, prod: monitoring.devths.com)
  monitoring_domain = var.environment == "prod" ? "monitoring.${var.domain_name}" : "monitoring.dev.${var.domain_name}"

  # Prometheus 데이터 보존 기간
  prometheus_retention = var.environment == "prod" ? "90d" : "30d"

  # 서버 레이블
  server_label = var.environment == "prod" ? "운영 모니터링 서버" : "개발 모니터링 서버"
}

# EC2 인스턴스 (모니터링 서버)
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
      monitoring_domain     = local.monitoring_domain
      environment           = var.environment
      grafana_admin_password = var.grafana_admin_password
      prometheus_retention  = local.prometheus_retention
      server_label          = local.server_label
      target_dev_ip         = var.target_dev_ip
      target_staging_ip     = var.target_staging_ip
      target_prod_ip        = var.target_prod_ip
    })
  )

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
      Type = "Monitoring"
    }
  )
}

# 공인 IP (모니터링 서버는 항상 EIP 사용)
resource "aws_eip" "monitoring" {
  instance = aws_instance.monitoring.id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.instance_name}-eip"
    }
  )
}
