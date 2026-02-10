# 환경별 도메인 설정을 위한 로컬 변수
locals {
  # 환경별 prefix (dev., stg., 또는 빈 문자열)
  env_prefix = var.environment == "prod" ? "" : "${var.environment}."

  # 서버 레이블 (fail2ban 알림용)
  server_label = var.environment == "prod" ? "운영 서버" : var.environment == "stg" ? "스테이징 서버" : "개발 서버"

  # CloudWatch Agent 네임스페이스
  cloudwatch_namespace = var.environment == "prod" ? "CWAgent/Production" : var.environment == "stg" ? "CWAgent/Staging" : "CWAgent/Dev"

  # Service 이름 매핑 (CodeDeploy 태그와 일치시키기 위해)
  service_name_map = {
    "fe"  = "Frontend"
    "be"  = "Backend"
    "ai"  = "Ai"
    "all" = "All"
  }
  service_name = lookup(local.service_name_map, var.service_type, "Unknown")
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

  # user_data를 gzip으로 압축하여 16KB 제한 우회
  user_data_base64 = base64gzip(join("\n", [
    "#!/bin/bash",
    templatefile("${path.module}/scripts/user_data.sh", {
      env_prefix           = local.env_prefix
      domain_name          = var.domain_name
      environment          = var.environment
      server_label         = local.server_label
      discord_webhook_url  = var.discord_webhook_url
      cloudwatch_namespace = local.cloudwatch_namespace
      service_type         = var.service_type
    }),
    file("${path.module}/scripts/install_node_exporter.sh"),
    file("${path.module}/scripts/setup_logrotate.sh"),
  ]))

  tags = merge(
    var.common_tags,
    {
      Name    = var.instance_name
      Service = local.service_name
      Version = var.infra_version
    }
  )
}

# 공인 IP
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
