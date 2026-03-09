# VPC 정보
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

# 퍼블릭 서브넷 (Web tier)
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = module.vpc.public_subnet_cidrs
}

# 프라이빗 서브넷 (App tier)
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = module.vpc.private_subnet_cidrs
}

# 데이터베이스 서브넷 (Data tier)
output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = module.vpc.database_subnet_cidrs
}

# 네트워크 게이트웨이
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "nat_type" {
  description = "NAT type being used"
  value       = module.vpc.nat_type
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (if using NAT Gateway)"
  value       = module.vpc.nat_gateway_ids
}

output "nat_instance_ids" {
  description = "List of NAT Instance IDs (if using NAT Instance)"
  value       = module.vpc.nat_instance_ids
}

output "nat_instance_private_ips" {
  description = "List of NAT Instance private IPs (if using NAT Instance)"
  value       = module.vpc.nat_instance_private_ips
}

output "nat_eip_public_ips" {
  description = "List of NAT Elastic IP addresses"
  value       = module.vpc.nat_eip_public_ips
}

# 라우트 테이블
output "public_route_table_id" {
  description = "Public route table ID"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of database route table IDs"
  value       = module.vpc.database_route_table_ids
}

# 보안 그룹 - ALB
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.vpc.alb_security_group_id
}

output "alb_security_group_name" {
  description = "ALB security group name"
  value       = module.vpc.alb_security_group_name
}

# 보안 그룹 - FE
output "fe_security_group_id" {
  description = "App security group ID"
  value       = module.vpc.fe_security_group_id
}

output "fe_security_group_name" {
  description = "App security group name"
  value       = module.vpc.fe_security_group_name
}

# 보안 그룹 - BE
output "be_security_group_id" {
  description = "App security group ID"
  value       = module.vpc.be_security_group_id
}

output "be_security_group_name" {
  description = "App security group name"
  value       = module.vpc.be_security_group_name
}

# 보안 그룹 - AI
output "ai_security_group_id" {
  description = "App security group ID"
  value       = module.vpc.ai_security_group_id
}

output "ai_security_group_name" {
  description = "App security group name"
  value       = module.vpc.ai_security_group_name
}

# 보안 그룹 - Database
output "database_security_group_id" {
  description = "Database security group ID"
  value       = module.vpc.database_security_group_id
}

output "database_security_group_name" {
  description = "Database security group name"
  value       = module.vpc.database_security_group_name
}

# 보안 그룹 - Mock
output "mock_security_group_id" {
  description = "Mock server security group ID"
  value       = module.vpc.mock_security_group_id
}

output "mock_security_group_name" {
  description = "Mock server security group name"
  value       = module.vpc.mock_security_group_name
}

# ============================================================================
# ALB 정보
# ============================================================================

output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias records)"
  value       = aws_lb.this.zone_id
}

# Target Group ARNs - Dev
output "dev_fe_target_group_arn" {
  description = "Dev Frontend target group ARN"
  value       = aws_lb_target_group.dev_fe.arn
}

output "dev_be_target_group_arn" {
  description = "Dev Backend target group ARN"
  value       = aws_lb_target_group.dev_be.arn
}

output "dev_ai_target_group_arn" {
  description = "Dev AI target group ARN"
  value       = aws_lb_target_group.dev_ai.arn
}

output "nonprod_grafana_target_group_arn" {
  description = "Nonprod Grafana target group ARN"
  value       = aws_lb_target_group.nonprod_grafana.arn
}

# Target Group ARNs - Stg
output "stg_fe_target_group_arn" {
  description = "Stg Frontend target group ARN"
  value       = aws_lb_target_group.stg_fe.arn
}

output "stg_be_target_group_arn" {
  description = "Stg Backend target group ARN"
  value       = aws_lb_target_group.stg_be.arn
}

output "stg_ai_target_group_arn" {
  description = "Stg AI target group ARN"
  value       = aws_lb_target_group.stg_ai.arn
}

output "stg_mock_target_group_arn" {
  description = "Stg Mock target group ARN"
  value       = aws_lb_target_group.stg_mock.arn
}

# ============================================================================
# Tempo S3 버킷
# ============================================================================

output "tempo_bucket_name" {
  description = "Tempo S3 bucket name"
  value       = module.s3_tempo.bucket_name
}

output "tempo_bucket_arn" {
  description = "Tempo S3 bucket ARN"
  value       = module.s3_tempo.bucket_arn
}

# ============================================================================
# Shared Artifact Bucket Outputs
# ============================================================================

output "artifact_bucket_name" {
  description = "S3 artifact bucket name"
  value       = module.s3_artifact.bucket_name
}

output "artifact_bucket_arn" {
  description = "S3 artifact bucket ARN"
  value       = module.s3_artifact.bucket_arn
}

output "artifact_bucket_id" {
  description = "S3 artifact bucket ID"
  value       = module.s3_artifact.bucket_id
}
