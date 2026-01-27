# VPC 생성
resource "aws_vpc" "devths_prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devths_v1_prod"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "devths_prod_igw" {
  vpc_id = aws_vpc.devths_prod.id

  tags = {
    Name = "devths_v1_prod_igw"
  }
}

# 퍼블릭 서브넷 1 (ap-northeast-2a)
resource "aws_subnet" "devths_prod_public_01" {
  vpc_id                  = aws_vpc.devths_prod.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "devths_v1_prod_public_01"
  }
}

# 퍼블릭 서브넷 2 (ap-northeast-2c)
resource "aws_subnet" "devths_prod_public_02" {
  vpc_id                  = aws_vpc.devths_prod.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "devths_prod_public_02"
  }
}

# 프라이빗 서브넷 1 (ap-northeast-2a)
resource "aws_subnet" "devths_prod_private_01" {
  vpc_id            = aws_vpc.devths_prod.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "devths_prod_private_01"
  }
}

# 프라이빗 서브넷 2 (ap-northeast-2c)
resource "aws_subnet" "devths_prod_private_02" {
  vpc_id            = aws_vpc.devths_prod.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "devths_prod_private_02"
  }
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "devths_prod_public" {
  vpc_id = aws_vpc.devths_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devths_prod_igw.id
  }

  tags = {
    Name = "devths_prod_public_rt"
  }
}

# 퍼블릭 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "devths_prod_public_01" {
  subnet_id      = aws_subnet.devths_prod_public_01.id
  route_table_id = aws_route_table.devths_prod_public.id
}

# 퍼블릭 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "devths_prod_public_02" {
  subnet_id      = aws_subnet.devths_prod_public_02.id
  route_table_id = aws_route_table.devths_prod_public.id
}

# Security Group
resource "aws_security_group" "devths_prod_ec2" {
  name        = "devths-v1-prod"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.devths_prod.id

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

  # 모든 아웃바운드 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devths-v1-prod"
  }
}
