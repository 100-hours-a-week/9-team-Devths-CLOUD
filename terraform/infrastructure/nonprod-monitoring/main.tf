# 테라폼 설정
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 프로바이더 설정
provider "aws" {
  region = var.aws_region
}

# 공유 VPC 참조 (Non-Prod VPC)
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../common/vpc-nonprod-v2/terraform.tfstate"
  }
}

# Dev 환경 상태 참조 (Dev EC2 Private IP)
data "terraform_remote_state" "dev" {
  backend = "local"
  config = {
    path = "../dev/terraform.tfstate"
  }
}

# Staging 환경 상태 참조 (Staging EC2 Private IP)
data "terraform_remote_state" "staging" {
  backend = "local"
  config = {
    path = "../staging/terraform.tfstate"
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

# 모니터링 서버 모듈
module "monitoring" {
  source = "../../modules/monitoring"

  instance_name             = "${var.project_name}-v2-monitoring-${var.environment}"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  vpc_id                    = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr                  = data.aws_vpc.nonprod.cidr_block
  iam_instance_profile_name = data.aws_iam_instance_profile.ec2_profile.name
  environment               = var.environment
  domain_name               = var.domain_name
  grafana_admin_password    = var.grafana_admin_password
  root_volume_size          = var.root_volume_size

  # 모니터링 대상 IP 주소
  target_dev_ip     = data.terraform_remote_state.dev.outputs.ec2_private_ip
  target_staging_ip = data.terraform_remote_state.staging.outputs.ec2_private_ip

  common_tags = var.common_tags
}

# Route53 A 레코드 (monitoring.dev.devths.com)
resource "aws_route53_record" "monitoring" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "monitoring.dev.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [module.monitoring.instance_public_ip]

  depends_on = [module.monitoring]
}

# API 서버 Security Group 업데이트 (Exporter 포트 허용)
# Dev 서버 Security Group에 규칙 추가
resource "aws_security_group_rule" "dev_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.ec2_security_group_id
  description              = "Node Exporter from monitoring server"
}

resource "aws_security_group_rule" "dev_nginx_exporter" {
  type                     = "ingress"
  from_port                = 9113
  to_port                  = 9113
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.ec2_security_group_id
  description              = "Nginx Exporter from monitoring server"
}
