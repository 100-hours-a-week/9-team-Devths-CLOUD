# ============================================================================
# Prod K8s Network VPC
# ============================================================================
#
# 구성 파일:
# - main.tf                    : Terraform 설정, Provider, VPC 모듈
# - variables.tf               : 입력 변수
# - outputs.tf                 : 출력 값
# - security_groups.tf         : K8s 보안그룹 (Master, Worker)
# - nat-iam.tf                 : NAT Instance IAM 역할
# - s3_artifact.tf             : Code Deploy용 S3 버킷
# - s3_tempo.tf                : Tempo용 S3 버킷
# ============================================================================

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "devths-state-terraform"
    key     = "prod-k8s/network/terraform.tfstate"
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
  environment           = "prod"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones

  # NAT Gateway 설정
  nat_type   = var.nat_type
  single_nat = var.single_nat

  # SSH 연결
  ssh_allowed_cidr         = null
  additional_ingress_rules = []
  common_tags              = var.common_tags
}
