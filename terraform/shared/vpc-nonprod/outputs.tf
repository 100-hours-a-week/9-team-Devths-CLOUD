# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# 퍼블릭 서브넷 ID
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# 프라이빗 서브넷 ID
output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# EC2 보안 그룹 ID
output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = module.vpc.ec2_security_group_id
}

# 인터넷 게이트웨이 ID
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}
