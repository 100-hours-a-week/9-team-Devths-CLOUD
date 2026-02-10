# S3 버킷 이름
output "artifact_bucket_name" {
  description = "S3 artifact bucket name"
  value       = module.s3_artifact.bucket_name
}

# S3 버킷 ARN
output "artifact_bucket_arn" {
  description = "S3 artifact bucket ARN"
  value       = module.s3_artifact.bucket_arn
}

# S3 버킷 ID
output "artifact_bucket_id" {
  description = "S3 artifact bucket ID"
  value       = module.s3_artifact.bucket_id
}
