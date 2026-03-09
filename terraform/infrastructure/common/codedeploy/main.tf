# ============================================================================
# Code Deploy
# ============================================================================

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "devths-state-terraform"
    key    = "common/codedeploy/terraform.tfstate"
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
# 프런트 엔드
# ============================================================================
resource "aws_codedeploy_app" "fe" {
  name             = var.codedeploy_app_name_fe
  compute_platform = "Server"

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = var.codedeploy_app_name_fe
      Service = "Frontend"
    }
  )
}

# ============================================================================
# 백엔드
# ============================================================================
resource "aws_codedeploy_app" "be" {
  name             = var.codedeploy_app_name_be
  compute_platform = "Server"

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = var.codedeploy_app_name_be
      Service = "Backend"
    }
  )
}

# ============================================================================
# 인공지능
# ============================================================================
resource "aws_codedeploy_app" "ai" {
  name             = var.codedeploy_app_name_ai
  compute_platform = "Server"

  # 태그
  tags = merge(
    var.common_tags,
    {
      Name    = var.codedeploy_app_name_ai
      Service = "AI"
    }
  )
}
