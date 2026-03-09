# ============================================================================
# VPC Peering Connection
# ============================================================================
#
# 기존에 콘솔에서 생성한 VPC Peering을 Terraform으로 관리하기 위한 설정
# Requester: vpc-0d0ed10e5a4820e8b (10.0.0.0/16)
# Accepter: vpc-05760e69b7799325d (192.168.0.0/16) - nonprod VPC
#
# Import 명령:
# terraform import aws_vpc_peering_connection.to_v1 pcx-03562d40db52265ad
# terraform import aws_route.private_to_v1 rtb-011f891b3fc7066a8_10.0.0.0/16
# terraform import aws_route.database_to_v1 rtb-08d2492af80ecd71f_10.0.0.0/16
# ============================================================================

# VPC Peering Connection (기존 리소스를 import하여 관리)
resource "aws_vpc_peering_connection" "to_v1" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = "vpc-0d0ed10e5a4820e8b"
  peer_owner_id = "174678835309"
  # peer_region은 같은 리전에서 auto_accept = true 사용 시 설정 불가
  auto_accept = true

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name = "devths-mg-V2"
    }
  )

  lifecycle {
    # 기존 리소스이므로 특정 속성 변경 무시
    ignore_changes = [tags]
  }
}

# Private Route Table에 Peering Route 추가
resource "aws_route" "private_to_v1" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.to_v1.id

  lifecycle {
    # Route Table의 ignore_changes와 충돌 방지
    ignore_changes = all
  }
}

# Database Route Table에 Peering Route 추가
resource "aws_route" "database_to_v1" {
  route_table_id            = module.vpc.database_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.to_v1.id

  lifecycle {
    # Route Table의 ignore_changes와 충돌 방지
    ignore_changes = all
  }
}
