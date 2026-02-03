# 테라폼 설정
terraform {
  required_version = ">= 1.0"

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

# Route53 Hosted Zone 생성
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform - Main hosted zone for ${var.domain_name}"

  tags = merge(
    var.common_tags,
    {
      Name        = var.domain_name
      Environment = "shared"
      ManagedBy   = "Terraform"
    }
  )
}
