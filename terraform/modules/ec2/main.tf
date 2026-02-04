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
  # 환경별 prefix (dev., stg., 또는 빈 문자열)
  env_prefix = var.environment == "prod" ? "" : "${var.environment}."

  # Frontend server names (production만 www 별칭 추가)
  fe_server_names = var.environment == "prod" ? "${var.domain_name} www.${var.domain_name}" : "${local.env_prefix}${var.domain_name}"

  # Certbot 도메인 리스트
  certbot_domains = var.environment == "prod" ? "-d ${var.domain_name} -d www.${var.domain_name} -d api.${var.domain_name} -d ai.${var.domain_name}" : "-d ${local.env_prefix}${var.domain_name} -d ${local.env_prefix}api.${var.domain_name} -d ${local.env_prefix}ai.${var.domain_name}"

  # SSL 인증서 경로에 사용될 도메인 (Certbot이 첫 번째 도메인으로 디렉토리 생성)
  ssl_cert_domain = var.environment == "prod" ? var.domain_name : "${local.env_prefix}${var.domain_name}"

  # 서버 레이블 (fail2ban 알림용)
  server_label = var.environment == "prod" ? "운영 서버" : var.environment == "stg" ? "스테이징 서버" : "개발 서버"
}

# EC2 인스턴스
resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile_name

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
  }

  user_data = join("\n", [
    "#!/bin/bash",
    templatefile("${path.module}/scripts/user_data.sh", {
      env_prefix          = local.env_prefix
      domain_name         = var.domain_name
      fe_server_names     = local.fe_server_names
      certbot_domains     = local.certbot_domains
      ssl_cert_domain     = local.ssl_cert_domain
      environment         = var.environment
      server_label        = local.server_label
      discord_webhook_url = var.discord_webhook_url
    }),
    file("${path.module}/scripts/init_db.sh"),
    file("${path.module}/scripts/setup_logrotate.sh"),
  ])

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
    }
  )
}

# 공인 IP (선택적)
resource "aws_eip" "this" {
  count    = var.enable_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.instance_name}-eip"
    }
  )
}
