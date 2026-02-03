terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 공유 S3 Artifact 버킷 - Dev와 Staging이 공유
module "s3_artifact" {
  source = "../../modules/s3"

  bucket_name        = "${var.project_name}-v1-artifact-nonprod"
  purpose            = "CodeDeploy artifacts for Dev and Staging"
  versioning_enabled = true

  lifecycle_rules = [
    {
      id              = "delete_old_versions"
      status          = "Enabled"
      noncurrent_days = 90
      expiration_days = null
    },
    {
      id              = "delete_old_artifacts"
      status          = "Enabled"
      noncurrent_days = null
      expiration_days = 180
    }
  ]

  common_tags = var.common_tags
}
