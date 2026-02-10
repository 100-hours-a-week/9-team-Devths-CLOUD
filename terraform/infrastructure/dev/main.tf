# ============================================================================
# Dev 환경
# ============================================================================
#
# 이 환경은 개발(Development) 환경을 위한 인프라를 정의합니다.
#
# 구성 파일:
# - main.tf         : Terraform 설정, Provider, Remote State 참조
# - ssm.tf          : SSM Parameter Store
# - iam.tf          : IAM 역할 및 정책
# - s3.tf           : S3 Storage 버킷
# - ec2.tf          : EC2 인스턴스 (Frontend, Backend, AI)
# - codedeploy.tf   : CodeDeploy 배포 그룹
# - route53.tf      : Route53 DNS 레코드
# - variables.tf    : 입력 변수
# - outputs.tf      : 출력 값
#
# ============================================================================

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

# 테라폼 설정 - 프로바이더
provider "aws" {
  region = var.aws_region
}

# ============================================================================
# Remote State 참조
# ============================================================================

# 공유 VPC 참조 (vpc-nonprod-v2 사용)
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../common/vpc-nonprod-v2/terraform.tfstate"
  }
}

# 공유 S3 Artifact 버킷 참조
data "terraform_remote_state" "s3" {
  backend = "local"
  config = {
    path = "../common/s3-nonprod-v2/terraform.tfstate"
  }
}

# 공유 SSM Session Manager 로그 설정 참조
data "terraform_remote_state" "ssm" {
  backend = "local"
  config = {
    path = "../common/ssm/terraform.tfstate"
  }
}
