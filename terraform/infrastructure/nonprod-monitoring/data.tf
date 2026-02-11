# ============================================================================
# Data Sources
# ============================================================================

# 공유 VPC 참조 (Non-Prod VPC)
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../common/vpc-nonprod-v2/terraform.tfstate"
  }
}

# 공유 Route53 Hosted Zone 참조
data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}

# VPC CIDR 조회 (state에 vpc_cidr output이 없으므로 직접 조회)
data "aws_vpc" "nonprod" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

# IAM 역할 (기본 EC2 역할 사용 - SSM 접근용)
data "aws_iam_role" "ec2_role" {
  name = "Devths-EC2-Dev"
}

data "aws_iam_instance_profile" "ec2_profile" {
  name = "Devths-EC2-Dev"
}

# ALB 타겟 그룹 참조
data "aws_lb_target_group" "grafana" {
  name = "${var.project_name}-v2-nonprod-grafana-tg"
}
