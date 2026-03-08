output "ecr_repository_urls" {
  description = "Map of ECR repository names to their URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository names to their ARNs"
  value       = module.ecr.repository_arns
}

output "ecr_registry_id" {
  description = "The registry ID where the repositories are created"
  value       = module.ecr.registry_id
}
