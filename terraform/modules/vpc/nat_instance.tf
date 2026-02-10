# ============================================================================
# NAT Instance 리소스
# ============================================================================

# Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_nat" {
  count       = local.actual_nat_type == "instance" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

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

  # NAT 설정을 위한 User Data
  user_data = <<-EOF
              #!/bin/bash
              # NAT 기능 활성화
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              sysctl -p

              # iptables NAT 설정
              /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              /sbin/iptables-save > /etc/iptables.rules

              # 재부팅 후에도 iptables 규칙 유지
              cat > /etc/rc.local <<'RCLOCAL'
              #!/bin/bash
              /sbin/iptables-restore < /etc/iptables.rules
              RCLOCAL
              chmod +x /etc/rc.local
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
