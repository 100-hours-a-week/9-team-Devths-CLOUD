# ============================================================================
# VPC
# ============================================================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

# VPC 대역
output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

# ============================================================================
# 서브넷
# ============================================================================
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

# 프라이빗 서브넷
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

# 데이터베이스 서브넷
output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = aws_subnet.database[*].cidr_block
}

# ============================================================================
# 라우팅 테이블
# ============================================================================

## 퍼블릭 라우팅 테이블
output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

# 프라이빗 라우트 테이블
output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

# DB 라우트 테이블
output "database_route_table_ids" {
  description = "List of database route table IDs"
  value       = aws_route_table.database[*].id
}

# ============================================================================
# 인터넷 게이트웨이
# ============================================================================
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

# ============================================================================
# NAT
# ============================================================================
output "nat_type" {
  description = "NAT type being used (gateway, instance, or none)"
  value       = local.actual_nat_type
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (if using NAT Gateway)"
  value       = aws_nat_gateway.this[*].id
}

output "nat_instance_ids" {
  description = "List of NAT Instance IDs (if using NAT Instance)"
  value       = aws_instance.nat[*].id
}

output "nat_instance_private_ips" {
  description = "List of NAT Instance private IPs (if using NAT Instance)"
  value       = aws_instance.nat[*].private_ip
}

output "nat_eip_public_ips" {
  description = "List of NAT Elastic IP addresses"
  value       = concat(aws_eip.nat_gateway[*].public_ip, aws_eip.nat_instance[*].public_ip)
}

# ============================================================================
# ALB
# ============================================================================
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "alb_security_group_name" {
  description = "ALB security group name"
  value       = aws_security_group.alb.name
}


# ============================================================================
# VPC 엔드포인트
# ============================================================================

output "s3_vpc_endpoint_id" {
  description = "S3 VPC Gateway Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_vpc_endpoint_state" {
  description = "S3 VPC Gateway Endpoint state"
  value       = aws_vpc_endpoint.s3.state
}

output "ecr_api_vpc_endpoint_id" {
  description = "ECR API VPC Interface Endpoint ID"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_vpc_endpoint_id" {
  description = "ECR DKR VPC Interface Endpoint ID"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "vpc_endpoints_security_group_id" {
  description = "VPC Endpoints security group ID"
  value       = aws_security_group.vpc_endpoints.id
}
