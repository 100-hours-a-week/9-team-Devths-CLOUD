# ============================================================================
# VPC & 네트워크 기본 구성
# ============================================================================

# ============================================================================
# VPC
# ============================================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-vpc"
    }
  )
}

# ============================================================================
# 인터넷 게이트웨이
# ============================================================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-igw"
    }
  )
}

# ============================================================================
# 서브넷
# ============================================================================

# 퍼블릭 서브넷
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-public-${count.index + 1}"
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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-private-${count.index + 1}"
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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-db-${count.index + 1}"
      Type = "Database"
    }
  )
}

# ============================================================================
# 라우트 테이블
# ============================================================================

# 퍼블릭 라우트 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-public-rt"
    }
  )

  # 코드와 실제 환경의 차이(Drift)를 의도적으로 허용
  lifecycle {
    ignore_changes = [route]
  }
}

# 퍼블릭 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
