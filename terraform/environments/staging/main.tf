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

# SSM Parameter Store 모듈
module "ssm_parameters" {
  source = "../../modules/ssm_parameters"

  environment_prefix = "Stg"
  common_tags        = var.common_tags
}

# IAM 모듈
module "iam" {
  source = "../../modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  environment_prefix  = "Stg"
  kms_key_arn         = module.ssm_parameters.kms_key_arn
  artifact_bucket_arn = data.terraform_remote_state.s3.outputs.artifact_bucket_arn
  common_tags         = var.common_tags

  depends_on = [module.ssm_parameters]
}

# S3 모듈 - Storage 버킷 (환경별로 분리)
module "s3_storage" {
  source = "../../modules/s3"

  bucket_name        = "${var.project_name}-storage-${var.environment}"
  purpose            = "Staging storage"
  versioning_enabled = true
  lifecycle_rules    = null

  common_tags = var.common_tags
}

# EC2 모듈
module "ec2" {
  source = "../../modules/ec2"

  instance_name              = "${var.project_name}-v1-${var.environment}"
  instance_type              = var.instance_type
  key_name                   = var.key_name
  subnet_id                  = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  security_group_id          = data.terraform_remote_state.vpc.outputs.ec2_security_group_id
  iam_instance_profile_name  = module.iam.ec2_instance_profile_name
  aws_region                 = var.aws_region
  enable_eip                 = var.enable_eip

  common_tags = var.common_tags

  depends_on = [module.iam]
}

# CodeDeploy 모듈 - Frontend
module "codedeploy_fe" {
  source = "../../modules/codedeploy"

  app_name               = "Devths-V1-FE"
  deployment_group_name  = "Devths-V1-FE-Staging-Group"
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
  deployment_group_name  = "Devths-V1-BE-Staging-Group"
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
  deployment_group_name  = "Devths-V1-AI-Staging-Group"
  service_role_arn       = module.iam.codedeploy_role_arn
  service_name           = "AI"
  ec2_tag_key            = "Name"
  ec2_tag_value          = module.ec2.instance_name
  deployment_config_name = var.deployment_config_name
  auto_rollback_enabled  = false

  common_tags = var.common_tags

  depends_on = [module.ec2, module.iam]
}

# Route53 모듈 (선택적)
module "route53" {
  count  = var.enable_route53 ? 1 : 0
  source = "../../modules/route53"

  domain_name       = "devths.com"
  subdomain_prefix  = "stg"
  eip_public_ip     = module.ec2.instance_public_ip
  create_www_record = false
  create_api_record = true
  create_ai_record  = true
  ttl               = 300

  common_tags = var.common_tags

  depends_on = [module.ec2]
}
