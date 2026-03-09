# ============================================================================
# Data Sources
# ============================================================================

# VPC 참조
data "terraform_remote_state" "prod" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "prod/network/terraform.tfstate"
    region = var.tf_state_region
  }
}

# 공유 Route53 Hosted Zone 참조
data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}

# VPC CIDR 조회 (Prod state에서 VPC ID 가져와서 조회)
data "aws_vpc" "prod" {
  id = data.terraform_remote_state.prod.outputs.vpc_id
}

# IAM 역할 (기본 EC2 역할 사용 - SSM 접근용)
data "aws_iam_role" "ec2_role" {
  name = "Devths-EC2-Prod"
}

data "aws_iam_instance_profile" "ec2_profile" {
  name = "Devths-EC2-Prod"
}

# ALB 타겟 그룹 참조 (Prod 모니터링용)
data "aws_lb_target_group" "monitoring" {
  name = "${var.project_name}-v2-prod-mon-tg"
}

# ALB 보안그룹 참조 (Prod 환경을 건드리지 않기 위해 직접 조회)
data "aws_security_group" "alb" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-v2-prod-alb-sg"]
  }

  vpc_id = data.terraform_remote_state.prod.outputs.vpc_id
}

# ASG 보안그룹 참조 (현재 prod 구조에 맞춰 활성화)
data "aws_security_group" "fe_asg" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-v2-prod-fe-sg"]
  }
  vpc_id = data.terraform_remote_state.prod.outputs.vpc_id
}

data "aws_security_group" "be_asg" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-v2-prod-be-sg"]
  }
  vpc_id = data.terraform_remote_state.prod.outputs.vpc_id
}

data "aws_security_group" "ai_asg" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-v2-prod-ai-sg"]
  }
  vpc_id = data.terraform_remote_state.prod.outputs.vpc_id
}
