# VPC 아이디
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

# VPC 대역
output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

# 퍼블릭 서브넷
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

## 퍼블릭 라우팅 테이블
output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
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

# 인터넷 게이트웨이
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}


# 보안 그룹
output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

output "ec2_security_group_name" {
  description = "EC2 security group name"
  value       = aws_security_group.ec2.name
}
