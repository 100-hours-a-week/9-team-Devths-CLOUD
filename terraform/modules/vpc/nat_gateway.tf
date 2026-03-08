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
