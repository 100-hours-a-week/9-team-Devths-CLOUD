# ============================================================================
# VPC
# ============================================================================

module "vpc" {
  source = "../../../modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones

  # NAT Gateway 사용
  nat_type   = var.nat_type
  single_nat = var.single_nat

  ssh_allowed_cidr         = null # SSH 비활성화 (SSM Session Manager 사용)
  additional_ingress_rules = []

  # 태그
  common_tags = var.common_tags
}
