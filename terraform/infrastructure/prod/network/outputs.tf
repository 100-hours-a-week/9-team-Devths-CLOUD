# ============================================================================
# VPC
# ============================================================================

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

# ============================================================================
# 보안그룹
# ============================================================================

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.vpc.alb_security_group_id
}

output "fe_security_group_id" {
  description = "Frontend security group ID"
  value       = module.vpc.fe_security_group_id
}

output "be_security_group_id" {
  description = "Backend security group ID"
  value       = module.vpc.be_security_group_id
}

output "ai_security_group_id" {
  description = "AI security group ID"
  value       = module.vpc.ai_security_group_id
}

# ============================================================================
# ALB
# ============================================================================

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.this.zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "target_group_fe_arn" {
  description = "Frontend Target Group ARN"
  value       = aws_lb_target_group.fe.arn
}

output "target_group_be_arn" {
  description = "Backend Target Group ARN"
  value       = aws_lb_target_group.be.arn
}

output "target_group_ai_arn" {
  description = "AI Target Group ARN"
  value       = aws_lb_target_group.ai.arn
}

output "target_group_monitoring_arn" {
  description = "Monitoring Target Group ARN"
  value       = aws_lb_target_group.monitoring.arn
}

# ============================================================================
# Route53 Outputs
# ============================================================================

output "domain_name" {
  description = "Primary domain name"
  value       = "devths.com"
}

output "frontend_urls" {
  description = "Frontend URLs"
  value = [
    "https://devths.com",
    "https://www.devths.com"
  ]
}

output "backend_url" {
  description = "Backend API URL"
  value       = "https://api.devths.com"
}

output "ai_url" {
  description = "AI API URL"
  value       = "https://ai.devths.com"
}

# ============================================================================
# VPC 엔드포인트
# ============================================================================

output "s3_vpc_endpoint_id" {
  description = "S3 VPC Gateway Endpoint ID"
  value       = module.vpc.s3_vpc_endpoint_id
}

output "ecr_api_vpc_endpoint_id" {
  description = "ECR API VPC Interface Endpoint ID"
  value       = module.vpc.ecr_api_vpc_endpoint_id
}

output "ecr_dkr_vpc_endpoint_id" {
  description = "ECR DKR VPC Interface Endpoint ID"
  value       = module.vpc.ecr_dkr_vpc_endpoint_id
}

# ============================================================================
# ACM
# ============================================================================

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = data.aws_acm_certificate.prod.arn
}

# ============================================================================
# S3
# ============================================================================

output "artifact_bucket_arn" {
  description = "V1 Artifact bucket ARN"
  value       = module.s3_artifact.bucket_arn
}

output "artifact_bucket_v2_arn" {
  description = "V2 Artifact bucket ARN"
  value       = module.s3_artifact_v2.bucket_arn
}

output "artifact_bucket_name" {
  description = "V1 Artifact bucket name"
  value       = module.s3_artifact.bucket_name
}

output "artifact_bucket_v2_name" {
  description = "V2 Artifact bucket name"
  value       = module.s3_artifact_v2.bucket_name
}

output "tempo_bucket_name" {
  description = "Tempo S3 bucket name"
  value       = module.s3_tempo.bucket_name
}

output "tempo_bucket_arn" {
  description = "Tempo S3 bucket ARN"
  value       = module.s3_tempo.bucket_arn
}
