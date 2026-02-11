# ============================================================================
# VPC Endpoints
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
# 필요시 특정 버킷이나 작업으로 제한 가능
# !TODO S3 리소스 환경별로 제한거는것 필요할 듯
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
