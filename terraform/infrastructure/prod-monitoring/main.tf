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

# Prod 환경 상태 참조 (Prod는 자체 VPC를 생성하므로 prod state에서 가져옴)
data "terraform_remote_state" "prod" {
  backend = "local"
  config = {
    path = "../prod/terraform.tfstate"
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

# 모니터링 서버 모듈
module "monitoring" {
  source = "../../modules/monitoring"

  instance_name             = "${var.project_name}-v1-monitoring-${var.environment}"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.prod.outputs.private_subnet_ids[0]
  vpc_id                    = data.terraform_remote_state.prod.outputs.vpc_id
  vpc_cidr                  = data.aws_vpc.prod.cidr_block
  iam_instance_profile_name = data.aws_iam_instance_profile.ec2_profile.name
  environment               = var.environment
  domain_name               = var.domain_name
  grafana_admin_password    = var.grafana_admin_password
  root_volume_size          = var.root_volume_size

  # 모니터링 대상 IP 주소
  target_prod_ip = data.terraform_remote_state.prod.outputs.ec2_private_ip

  common_tags = var.common_tags
}

# Route53 A 레코드 (monitoring.devths.com)
resource "aws_route53_record" "monitoring" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "monitoring.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [module.monitoring.instance_private_ip]

  depends_on = [module.monitoring]
}

# API 서버 Security Group 업데이트 (Exporter 포트 허용)
# Prod 서버 Security Group에 규칙 추가
resource "aws_security_group_rule" "prod_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.prod.outputs.ec2_security_group_id
  description              = "Node Exporter from monitoring server"
}

resource "aws_security_group_rule" "prod_nginx_exporter" {
  type                     = "ingress"
  from_port                = 9113
  to_port                  = 9113
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.prod.outputs.ec2_security_group_id
  description              = "Nginx Exporter from monitoring server"
}
