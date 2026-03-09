# ============================================================================
# Nonprod Monitoring Environment
# ============================================================================
#
# 이 환경은 Dev/Staging 환경을 모니터링하기 위한 Grafana + Prometheus 서버를 배포합니다.
#
# 구성 파일:
# - main.tf             : Terraform 설정, Provider
# - data.tf             : Data sources (VPC, IAM, Remote States)
# - monitoring.tf       : 모니터링 서버 모듈
# - alb_target_attachments.tf              : ALB 타겟 그룹 연결
# - route53.tf          : Route53 DNS 레코드
# - security_groups_attachment.tf  : Security Group 규칙 (Exporter 포트)
# - variables.tf        : 입력 변수
# - outputs.tf          : 출력 값
#
# ============================================================================

# 테라폼 설정
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "devths-state-terraform"
    key    = "nonprod/monitoring/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt        = true
  }

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

# ============================================================================
# Remote State 참조
# ============================================================================