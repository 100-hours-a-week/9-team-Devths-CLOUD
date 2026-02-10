# ============================================================================
# NAT Instance 리소스
# ============================================================================

# NAT Instance를 위한 Elastic IP
resource "aws_eip" "nat_instance" {
  count  = local.actual_nat_type == "instance" ? local.nat_count : 0
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-${var.environment}-nat-instance-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# NAT Instance 보안 그룹
resource "aws_security_group" "nat_instance" {
  count       = local.actual_nat_type == "instance" ? 1 : 0
  name        = "${var.project_name}-v2-${var.environment}-nat-instance-sg"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.this.id

  # Private/DB 서브넷에서의 모든 트래픽 허용
  ingress {
    description = "All traffic from Private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = concat(var.private_subnet_cidrs, var.database_subnet_cidrs)
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-${var.environment}-nat-instance-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# NAT Instance
resource "aws_instance" "nat" {
  count                       = local.actual_nat_type == "instance" ? local.nat_count : 0
  ami                         = data.aws_ami.amazon_linux_nat[0].id
  instance_type               = var.nat_instance_type
  key_name                    = var.nat_key_name
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = [aws_security_group.nat_instance[0].id]
  associate_public_ip_address = true
  source_dest_check           = false # NAT를 위해 필수
  iam_instance_profile        = var.nat_iam_instance_profile_name

  # NAT 설정을 위한 User Data
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 로그 설정
              exec > >(tee /var/log/user-data.log)
              exec 2>&1

              echo "=== NAT Instance User Data 시작 ==="

              # NAT 기능 활성화
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              sysctl -p
              echo "✓ IP forwarding 활성화 완료"

              # iptables NAT 설정
              /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              /sbin/iptables-save > /etc/iptables.rules
              echo "✓ iptables NAT 설정 완료"

              # 재부팅 후에도 iptables 규칙 유지
              cat > /etc/rc.local <<'RCLOCAL'
              #!/bin/bash
              /sbin/iptables-restore < /etc/iptables.rules
              RCLOCAL
              chmod +x /etc/rc.local
              echo "✓ iptables 영구 설정 완료"

              # SSM Agent 설치 및 시작 (Amazon Linux 2023)
              echo "SSM Agent 설정 시작..."

              # SSM Agent가 이미 설치되어 있는지 확인
              if ! systemctl is-active --quiet amazon-ssm-agent; then
                  echo "SSM Agent 설치 및 시작..."
                  dnf install -y amazon-ssm-agent
                  systemctl enable amazon-ssm-agent
                  systemctl start amazon-ssm-agent
              else
                  echo "SSM Agent가 이미 실행 중입니다."
                  systemctl restart amazon-ssm-agent
              fi

              # SSM Agent 상태 확인
              systemctl status amazon-ssm-agent --no-pager
              echo "✓ SSM Agent 설정 완료"

              # CloudWatch Agent 설치 (선택 사항, 모니터링용)
              echo "CloudWatch Agent 설치..."
              dnf install -y amazon-cloudwatch-agent
              echo "✓ CloudWatch Agent 설치 완료"

              echo "=== NAT Instance User Data 완료 ==="
              EOF

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-v2-${var.environment}-nat-instance-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# NAT Instance에 EIP 연결
resource "aws_eip_association" "nat_instance" {
  count         = local.actual_nat_type == "instance" ? local.nat_count : 0
  instance_id   = aws_instance.nat[count.index].id
  allocation_id = aws_eip.nat_instance[count.index].id
}
