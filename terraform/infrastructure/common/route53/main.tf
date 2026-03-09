# ============================================================================
# Route53
# ============================================================================
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "devths-state-terraform"
    key    = "common/route53/terraform.tfstate"
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

# 프로바이더 설정
provider "aws" {
  region = var.aws_region
}


# ============================================================================
# 생성
# ============================================================================
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform - Main hosted zone for ${var.domain_name}"

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name        = var.domain_name
    }
  )
}
