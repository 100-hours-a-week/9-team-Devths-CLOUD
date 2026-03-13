# ============================================================================
# NonProd Network VPC
# ============================================================================
#
# 구성 파일:
# - main.tf                    : Terraform 설정, Provider, VPC 모듈
# - alb_target_attachments.tf                     : Application Load Balancer
# - alb_target_groups.tf       : ALB Target Groups (FE, BE, AI, Monitoring)
# - alb_target_attachments.tf  : Target Group Attachments (태그 기반 자동 등록)
# - alb_listeners.tf           : HTTP/HTTPS Listeners
# - alb_listener_rules.tf      : 호스트 기반 라우팅 규칙
# - variables.tf               : 입력 변수
# - outputs.tf                 : 출력 값
# ============================================================================

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "devths-state-terraform"
    key     = "nonprod-k8s/network/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
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
# VPC 모듈
# ============================================================================

module "vpc" {
  source = "../../../modules/vpc"

  # 기본 설정
  project_name          = var.project_name
  environment           = "nonprod"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones

  # NAT 및 엔드포인트 설정
  nat_type                      = var.nat_type
  single_nat                    = var.single_nat
  nat_instance_type             = var.nat_instance_type
  nat_key_name                  = "devths-non-prod"
  nat_iam_instance_profile_name = aws_iam_instance_profile.nat_instance.name

  # SSH 연결
  ssh_allowed_cidr         = null
  additional_ingress_rules = []
  common_tags              = var.common_tags

  depends_on = [aws_iam_instance_profile.nat_instance]

}
