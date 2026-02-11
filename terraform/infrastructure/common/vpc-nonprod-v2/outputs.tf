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

# Target Group ARNs
output "fe_target_group_arn" {
  description = "Frontend target group ARN"
  value       = aws_lb_target_group.fe.arn
}

output "be_target_group_arn" {
  description = "Backend target group ARN"
  value       = aws_lb_target_group.be.arn
}

output "ai_target_group_arn" {
  description = "AI target group ARN"
  value       = aws_lb_target_group.ai.arn
}

output "grafana_target_group_arn" {
  description = "Grafana target group ARN"
  value       = aws_lb_target_group.grafana.arn
}
