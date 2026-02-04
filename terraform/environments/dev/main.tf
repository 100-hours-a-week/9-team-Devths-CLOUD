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

# 공유 VPC 참조
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../../shared/vpc-nonprod/terraform.tfstate"
  }
}

# 공유 S3 Artifact 버킷 참조
data "terraform_remote_state" "s3" {
  backend = "local"
  config = {
    path = "../../shared/s3-nonprod/terraform.tfstate"
  }
}

# 공유 SSM Session Manager 로그 설정 참조
data "terraform_remote_state" "ssm" {
  backend = "local"
  config = {
    path = "../../shared/ssm/terraform.tfstate"
  }
}

# SSM Parameter Store 모듈
module "ssm_parameters" {
  source = "../../modules/ssm_parameters"

  environment_prefix    = "Dev"
  be_parameter_values   = var.be_parameter_values
  ai_parameter_values   = var.ai_parameter_values
  common_tags           = var.common_tags
}

# IAM 모듈
module "iam" {
  source = "../../modules/iam"

  project_name               = var.project_name
  environment                = var.environment
  environment_prefix         = "Dev"
  kms_key_arn                = module.ssm_parameters.kms_key_arn
  artifact_bucket_arn        = data.terraform_remote_state.s3.outputs.artifact_bucket_arn
  storage_bucket_arn         = module.s3_storage.bucket_arn
  ssm_log_bucket_arn         = data.terraform_remote_state.ssm.outputs.ssm_log_bucket_arn
  cloudwatch_log_group_arn   = data.terraform_remote_state.ssm.outputs.cloudwatch_log_group_arn
  common_tags                = var.common_tags

  depends_on = [module.ssm_parameters, module.s3_storage]
}

# S3 모듈 - Storage 버킷 (환경별로 분리)
module "s3_storage" {
  source = "../../modules/s3"

  bucket_name        = "${var.project_name}-storage-${var.environment}"
  purpose            = "Development storage"
  versioning_enabled = true

  # 퍼블릭 읽기 활성화
  block_public_access = false
  enable_public_read  = true

  # CORS 설정
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE"]
      allowed_origins = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://dev.devths.com",
        "https://dev.api.devths.com",
        "https://dev.ai.devths.com"
      ]
      expose_headers  = ["Access-Control-Allow-Origin"]
      max_age_seconds = 3000
    }
  ]

  lifecycle_rules = [
    {
      id              = "delete_old_versions"
      status          = "Enabled"
      noncurrent_days = 30
      expiration_days = null
    },
    {
      id              = "delete_old_artifacts"
      status          = "Enabled"
      noncurrent_days = null
      expiration_days = 7
    }
  ]

  common_tags = var.common_tags
}

# EC2 모듈
module "ec2" {
  source = "../../modules/ec2"

  instance_name             = "${var.project_name}-v1-${var.environment}"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  security_group_id         = data.terraform_remote_state.vpc.outputs.ec2_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  aws_region                = var.aws_region
  enable_eip                = var.enable_eip
  environment               = var.environment
  domain_name               = "devths.com"

  common_tags = var.common_tags

  depends_on = [module.iam]
}

# CodeDeploy Application은 `terraform/shared/codedeploy`에서 공통으로 생성합니다.
# CodeDeploy 모듈 - Frontend
module "codedeploy_fe" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-V1-FE"
  deployment_group_name  = "Devths-V1-FE-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Frontend"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}

# CodeDeploy 모듈 - Backend
module "codedeploy_be" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-V1-BE"
  deployment_group_name  = "Devths-V1-BE-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "Backend"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}

# CodeDeploy 모듈 - AI
module "codedeploy_ai" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-V1-AI"
  deployment_group_name  = "Devths-V1-AI-Dev-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "AI"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}

# Route53 모듈 - EC2 public IP 기반으로 항상 레코드 생성
module "route53" {
  source = "../../modules/route53"

  domain_name       = "devths.com"
  subdomain_prefix  = "dev"
  public_ip         = module.ec2.instance_public_ip
  create_www_record = false
  create_api_record = true
  create_ai_record  = true
  ttl               = 60

  common_tags = var.common_tags

  depends_on = [module.ec2]
}
