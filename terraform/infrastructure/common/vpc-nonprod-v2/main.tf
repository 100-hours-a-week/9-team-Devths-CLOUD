# ============================================================================
# VPC NonProd V2 (Dev + Staging 공유 인프라)
# ============================================================================
#
# 이 환경은 Dev 및 Staging 환경에서 공유하는 VPC 및 ALB를 정의합니다.
#
# 구성 파일:
# - main.tf                    : Terraform 설정, Provider, VPC 모듈
# - alb.tf                     : Application Load Balancer
# - alb_target_groups.tf       : ALB Target Groups (FE, BE, AI, Monitoring)
# - alb_target_attachments.tf  : Target Group Attachments (태그 기반 자동 등록)
# - alb_listeners.tf           : HTTP/HTTPS Listeners
# - alb_listener_rules.tf      : 호스트 기반 라우팅 규칙
# - variables.tf               : 입력 변수
# - outputs.tf                 : 출력 값
#
# ============================================================================

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

# ============================================================================
# VPC 모듈
# ============================================================================

module "vpc" {
  source = "../../../modules/vpc"

  project_name          = var.project_name
  environment           = "nonprod"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones

  # NAT Instance 사용 (비용 절감)
  nat_type          = var.nat_type
  single_nat        = var.single_nat
  nat_instance_type = var.nat_instance_type
  nat_key_name      = "devths-non-prod"

  ssh_allowed_cidr         = null # SSH 비활성화
  additional_ingress_rules = []
  common_tags              = var.common_tags
}
