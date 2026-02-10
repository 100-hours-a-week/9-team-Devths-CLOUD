# 환경별 도메인 설정을 위한 로컬 변수
locals {
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

  # user_data는 base64 인코딩만 사용 (5KB < 16KB 제한, 디버깅 용이)
  user_data = join("\n", [
    "#!/bin/bash",
    file("${path.module}/scripts/user_data.sh"),
    file("${path.module}/scripts/install_node_exporter.sh"),
    file("${path.module}/scripts/setup_logrotate.sh"),
  ])

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
