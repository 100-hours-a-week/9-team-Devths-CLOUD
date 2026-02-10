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

# 3-tier VPC 모듈 - Docker 기반 아키텍처
module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  environment           = "nonprod"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones

  # NAT Instance 사용 (비용 절감을 위해)
  nat_type          = var.nat_type
  single_nat        = var.single_nat
  nat_instance_type = var.nat_instance_type
  nat_key_name      = "devths-non-prod"

  ssh_allowed_cidr         = null # SSH 비활성화
  additional_ingress_rules = []
  common_tags              = var.common_tags
}
