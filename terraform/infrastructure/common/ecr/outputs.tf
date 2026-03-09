# ============================================================================
# 레포지토리 주소들
# ============================================================================
output "ecr_repository_urls" {
  description = "Map of ECR repository names to their URLs"
  value       = module.ecr.repository_urls
}

# ============================================================================
# 레포지토리 ARN
# ============================================================================
output "ecr_repository_arns" {
  description = "Map of ECR repository names to their ARNs"
  value       = module.ecr.repository_arns
}


# ============================================================================
# 레포지토리 ID
# ============================================================================
output "ecr_registry_id" {
  description = "The registry ID where the repositories are created"
  value       = module.ecr.registry_id
}
