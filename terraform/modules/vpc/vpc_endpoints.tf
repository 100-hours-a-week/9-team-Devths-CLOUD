# ============================================================================
# VPC Gateway Endpoints
# ============================================================================

# S3 VPC Gateway Endpoint (프라이빗 서브넷에서 S3 접근용)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # 프라이빗 및 데이터베이스 라우트 테이블에 자동으로 라우트 추가
  route_table_ids = concat(
    aws_route_table.private[*].id,
    aws_route_table.database[*].id
  )

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-s3-endpoint"
    }
  )
}

# S3 VPC Endpoint Policy
# Note: ECR도 S3를 사용하므로 모든 S3 버킷 접근 허용
# 특정 버킷으로 제한 시 ECR 이미지 레이어 다운로드 실패 가능
resource "aws_vpc_endpoint_policy" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Access"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# ECR VPC Interface Endpoints (프라이빗 서브넷에서 ECR 접근용)
# ============================================================================

# ECR API Endpoint - ECR API 호출용 (레지스트리 인증, 이미지 메타데이터 등)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  # 프라이빗 서브넷에 ENI 생성
  subnet_ids = aws_subnet.private[*].id

  # VPC Endpoint 보안 그룹 (443 포트 허용)
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-ecr-api-endpoint"
    }
  )
}

# ECR DKR Endpoint - Docker 이미지 pull/push용
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  # 프라이빗 서브넷에 ENI 생성
  subnet_ids = aws_subnet.private[*].id

  # VPC Endpoint 보안 그룹 (443 포트 허용)
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-V2-${var.environment}-ecr-dkr-endpoint"
    }
  )
}
