# 버킷 ID
output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.this.id
}

# ARN
output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}

# 버킷명
output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}
