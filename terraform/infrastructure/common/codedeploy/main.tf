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

# CodeDeploy Application은 환경(dev/staging/prod)과 무관하게 공통으로 관리합니다.
resource "aws_codedeploy_app" "fe" {
  name             = var.codedeploy_app_name_fe
  compute_platform = "Server"

  tags = merge(
    var.common_tags,
    {
      Name    = var.codedeploy_app_name_fe
      Service = "Frontend"
    }
  )
}

resource "aws_codedeploy_app" "be" {
  name             = var.codedeploy_app_name_be
  compute_platform = "Server"

  tags = merge(
    var.common_tags,
    {
      Name    = var.codedeploy_app_name_be
      Service = "Backend"
    }
  )
}

resource "aws_codedeploy_app" "ai" {
  name             = var.codedeploy_app_name_ai
  compute_platform = "Server"

  tags = merge(
    var.common_tags,
    {
      Name    = var.codedeploy_app_name_ai
      Service = "AI"
    }
  )
}
