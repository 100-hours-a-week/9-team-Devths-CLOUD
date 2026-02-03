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

# 공유 VPC 모듈 - Dev와 Staging이 공유
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = "nonprod"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  ssh_allowed_cidr     = null # SSH 비활성화
  additional_ingress_rules = []
  common_tags          = var.common_tags
}
