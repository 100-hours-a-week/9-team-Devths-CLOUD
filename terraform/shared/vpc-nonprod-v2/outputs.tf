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

# 보안 그룹 - App
output "app_security_group_id" {
  description = "App security group ID"
  value       = module.vpc.app_security_group_id
}

output "app_security_group_name" {
  description = "App security group name"
  value       = module.vpc.app_security_group_name
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

# 보안 그룹 - EC2 (하위 호환성)
output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = module.vpc.ec2_security_group_id
}

output "ec2_security_group_name" {
  description = "EC2 security group name"
  value       = module.vpc.ec2_security_group_name
}
