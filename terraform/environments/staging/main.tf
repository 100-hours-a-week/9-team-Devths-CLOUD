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

# VPC 모듈
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  ssh_allowed_cidr     = null  # SSH 비활성화
  additional_ingress_rules = []
  common_tags          = var.common_tags
}

# IAM 모듈
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags
}

# S3 모듈 - Artifact 버킷
module "s3_artifact" {
  source = "../../modules/s3"

  bucket_name        = "${var.project_name}-artifact-${var.environment}"
  purpose            = "CodeDeploy artifacts"
  versioning_enabled = true

  lifecycle_rules = [
    {
      id              = "delete_old_versions"
      status          = "Enabled"
      noncurrent_days = 90
      expiration_days = null
    },
    {
      id              = "delete_old_artifacts"
      status          = "Enabled"
      noncurrent_days = null
      expiration_days = 180
    }
  ]

  common_tags = var.common_tags
}

# S3 모듈 - Storage 버킷
module "s3_storage" {
  source = "../../modules/s3"

  bucket_name        = "${var.project_name}-${var.environment}"
  purpose            = "Staging storage"
  versioning_enabled = true
  lifecycle_rules    = null

  common_tags = var.common_tags
}

# SSM 모듈 - Session Manager 설정
module "ssm" {
  source = "../../modules/ssm"

  project_name                  = var.project_name
  bucket_name                   = "devths-ssm-log"
  log_retention_days            = var.ssm_log_retention_days
  cloudwatch_streaming_enabled  = true
  idle_session_timeout          = "20"
  max_session_duration          = "60"

  common_tags = var.common_tags
}

# EC2 모듈
module "ec2" {
  source = "../../modules/ec2"

  instance_name              = "${var.project_name}-v1-${var.environment}"
  instance_type              = var.instance_type
  key_name                   = var.key_name
  subnet_id                  = module.vpc.public_subnet_ids[0]
  security_group_id          = module.vpc.ec2_security_group_id
  iam_instance_profile_name  = module.iam.ec2_instance_profile_name
  aws_region                 = var.aws_region

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

# Route53 모듈
module "route53" {
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
