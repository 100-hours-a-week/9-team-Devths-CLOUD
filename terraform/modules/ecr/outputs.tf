output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for repo_name, repo in aws_ecr_repository.this :
    repo_name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for repo_name, repo in aws_ecr_repository.this :
    repo_name => repo.arn
  }
}

output "registry_id" {
  description = "The registry ID where the repositories are created"
  value       = try(values(aws_ecr_repository.this)[0].registry_id, null)
}
