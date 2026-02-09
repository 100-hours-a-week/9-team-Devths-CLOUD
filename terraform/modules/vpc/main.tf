# VPC 생성
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-igw"
    }
  )
}

# 퍼블릭 서브넷
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-public-${count.index + 1}"
      Type = "Public"
    }
  )
}

# 프라이빗 서브넷
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-private-${count.index + 1}"
      Type = "Private"
    }
  )
}

# 데이터베이스 서브넷
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-db-${count.index + 1}"
      Type = "Database"
    }
  )
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-public-rt"
    }
  )
}

# 퍼블릭 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 하위 호환성 처리
locals {
  # enable_nat_gateway가 설정되어 있으면 그것 사용, 아니면 nat_type 사용
  actual_nat_type = var.enable_nat_gateway != null ? (var.enable_nat_gateway ? "gateway" : "none") : var.nat_type
  actual_single_nat = var.single_nat_gateway != null ? var.single_nat_gateway : var.single_nat

  nat_count = local.actual_nat_type == "none" ? 0 : (local.actual_single_nat ? 1 : length(var.availability_zones))
}

# ============================================================================
# NAT Gateway 리소스
# ============================================================================

# NAT Gateway를 위한 Elastic IP
resource "aws_eip" "nat_gateway" {
  count  = local.actual_nat_type == "gateway" ? local.nat_count : 0
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-nat-gw-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = local.actual_nat_type == "gateway" ? local.nat_count : 0
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-nat-gw-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# ============================================================================
# NAT Instance 리소스
# ============================================================================

# 최신 Amazon Linux 2023 AMI 조회 (NAT용)
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
      Name = "${var.project_name}v2-${var.environment}-nat-instance-${count.index + 1}"
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

# ============================================================================
# Private/Database 서브넷 라우트 테이블
# ============================================================================

# 프라이빗 라우트 테이블
resource "aws_route_table" "private" {
  count  = local.actual_nat_type != "none" ? local.nat_count : 0
  vpc_id = aws_vpc.this.id

  # NAT Gateway 사용 시
  dynamic "route" {
    for_each = local.actual_nat_type == "gateway" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[local.actual_single_nat ? 0 : count.index].id
    }
  }

  # NAT Instance 사용 시
  dynamic "route" {
    for_each = local.actual_nat_type == "instance" ? [1] : []
    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = aws_instance.nat[local.actual_single_nat ? 0 : count.index].primary_network_interface_id
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-private-rt${local.actual_single_nat ? "" : "-${count.index + 1}"}"
    }
  )
}

# 프라이빗 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "private" {
  count = local.actual_nat_type != "none" ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[local.actual_single_nat ? 0 : count.index].id
}

# 데이터베이스 라우트 테이블
resource "aws_route_table" "database" {
  count  = local.actual_nat_type != "none" && length(var.database_subnet_cidrs) > 0 ? local.nat_count : 0
  vpc_id = aws_vpc.this.id

  # NAT Gateway 사용 시
  dynamic "route" {
    for_each = local.actual_nat_type == "gateway" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[local.actual_single_nat ? 0 : count.index].id
    }
  }

  # NAT Instance 사용 시
  dynamic "route" {
    for_each = local.actual_nat_type == "instance" ? [1] : []
    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = aws_instance.nat[local.actual_single_nat ? 0 : count.index].primary_network_interface_id
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-db-rt${local.actual_single_nat ? "" : "-${count.index + 1}"}"
    }
  )
}

# 데이터베이스 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "database" {
  count = local.actual_nat_type != "none" && length(var.database_subnet_cidrs) > 0 ? length(aws_subnet.database) : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[local.actual_single_nat ? 0 : count.index].id
}

# ALB 보안그룹 (Public tier)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-v2-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.this.id

  # HTTP
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 outbound traffic
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
      Name = "${var.project_name}-v2-${var.environment}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# App 보안그룹 (Private tier - Docker containers)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-v2-${var.environment}-app-sg"
  description = "Security group for application tier (Docker containers)"
  vpc_id      = aws_vpc.this.id

  # HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Frontend port (Next.js)
  ingress {
    description     = "Frontend from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Backend port (Spring Boot)
  ingress {
    description     = "Backend from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # AI service port (FastAPI)
  ingress {
    description     = "AI service from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # 추가 규칙
  dynamic "ingress" {
    for_each = var.additional_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # 모든 outbound traffic
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
      Name = "${var.project_name}-v2-${var.environment}-app-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Database 보안그룹 (Database tier)
resource "aws_security_group" "database" {
  count       = length(var.database_subnet_cidrs) > 0 ? 1 : 0
  name        = "${var.project_name}-v2-${var.environment}-db-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.this.id

  # PostgreSQL from App tier
  ingress {
    description     = "PostgreSQL from App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # 모든 outbound traffic
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
      Name = "${var.project_name}-v2-${var.environment}-db-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 보안그룹 (하위 호환성 유지)
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-v2-${var.environment}-ec2"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.this.id

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 추가할 포트
  dynamic "ingress" {
    for_each = var.additional_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # 모든 outbound traffic
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
      Name = "${var.project_name}-v2-${var.environment}-ec2-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
