# ============================================================================
# 라우트 테이블
# ============================================================================

# ============================================================================
# Private 서브넷 라우트 테이블
# ============================================================================
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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-private-rt${local.actual_single_nat ? "" : "-${count.index + 1}"}"
    }
  )

  # 라우트는 무시
  lifecycle {
    ignore_changes = [route]
  }
}

# 프라이빗 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "private" {
  count = local.actual_nat_type != "none" ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[local.actual_single_nat ? 0 : count.index].id
}

# ============================================================================
# Database 서브넷 라우트 테이블
# ============================================================================
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

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.infra_version}-${var.environment}-db-rt${local.actual_single_nat ? "" : "-${count.index + 1}"}"
    }
  )

  # 라우트는 무시
  lifecycle {
    ignore_changes = [route]
  }
}

# 데이터베이스 서브넷 라우트 테이블 연결
resource "aws_route_table_association" "database" {
  count = local.actual_nat_type != "none" && length(var.database_subnet_cidrs) > 0 ? length(aws_subnet.database) : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[local.actual_single_nat ? 0 : count.index].id
}
