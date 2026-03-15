# ============================================================================
# ECR
# ============================================================================
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "devths-state-terraform"
    key    = "common/ecr/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt        = true
  }

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

# ============================================================================
# 레포지토리 생성
# ============================================================================
module "ecr" {
  source = "../../../modules/ecr"

  repositories         = var.ecr_repositories
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  encryption_type      = "AES256"

  # 이미지 라이프사이클 정책 (오래된 이미지 자동 삭제)
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # 태그
  common_tags = var.common_tags
}
