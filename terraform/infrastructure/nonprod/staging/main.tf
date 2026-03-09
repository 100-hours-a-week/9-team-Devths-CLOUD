# ============================================================================
# Staging 환경
# ============================================================================

# 테라폼 설정
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "devths-state-terraform"
    key    = "nonprod/staging/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# 테라폼 설정 - 프로바이더
provider "aws" {
  region = var.aws_region
}

locals {
  tf_state_bucket = var.tf_state_bucket
  tf_state_region = var.tf_state_region
}

# ============================================================================
# Remote State 참조
# ============================================================================

# 공유 VPC 참조 (nonprod/network 사용)
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "nonprod/network/terraform.tfstate"
    region = local.tf_state_region
  }
}

# 공유 S3 Artifact 버킷 참조
data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "nonprod/network/terraform.tfstate"
    region = local.tf_state_region
  }
}

# 공유 SSM Session Manager 로그 설정 참조
data "terraform_remote_state" "ssm" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "common/ssm/terraform.tfstate"
    region = local.tf_state_region
  }
}