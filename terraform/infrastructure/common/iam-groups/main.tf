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

# ===================================
# IAM 그룹
# ===================================

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/"
}

resource "aws_iam_group" "service_accounts" {
  name = "service-accounts"
  path = "/"
}

# ===================================
# 외부 IAM 사용자 참조
# ===================================

# GitHub Actions IAM 사용자 (shared/github-actions에서 생성됨)
data "aws_iam_user" "github_actions" {
  user_name = var.github_actions_user_name
}
