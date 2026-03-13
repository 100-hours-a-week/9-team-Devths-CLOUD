# ============================================================================
# VPC
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

# ============================================================================
# 퍼블릭 서브넷
# ============================================================================

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = module.vpc.public_subnet_cidrs
}

# ============================================================================
# 프라이빗 서브넷
# ============================================================================

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = module.vpc.private_subnet_cidrs
}

# ============================================================================
# DB 서브넷
# ============================================================================

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = module.vpc.database_subnet_cidrs
}

# ============================================================================
# 네트워크 게이트웨이
# ============================================================================

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

# ============================================================================
# 라우트 테이블
# ============================================================================

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

# ============================================================================
# ALB
# ============================================================================

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.vpc.alb_security_group_id
}

output "alb_security_group_name" {
  description = "ALB security group name"
  value       = module.vpc.alb_security_group_name
}

# ============================================================================
# 보안그룹 - K8s Master (Control Plane)
# ============================================================================

output "k8s_master_security_group_id" {
  description = "Kubernetes control-plane security group ID"
  value       = aws_security_group.k8s_master.id
}

output "k8s_master_security_group_name" {
  description = "Kubernetes control-plane security group name"
  value       = aws_security_group.k8s_master.name
}

# ============================================================================
# 보안그룹 - K8s Worker
# ============================================================================

output "k8s_worker_security_group_id" {
  description = "Kubernetes worker security group ID"
  value       = aws_security_group.k8s_worker.id
}

output "k8s_worker_security_group_name" {
  description = "Kubernetes worker security group name"
  value       = aws_security_group.k8s_worker.name
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
# 아티 팩트 버킷
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
