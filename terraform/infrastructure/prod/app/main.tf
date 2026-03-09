# ============================================================================
# Prod
# ============================================================================

terraform {
  required_version = ">= 1.0"

  backend "s3" {}

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

locals {
  tf_state_bucket = var.tf_state_bucket
  tf_state_region = var.tf_state_region
}

# ============================================================================
# SSM 참조
# ============================================================================
data "terraform_remote_state" "ssm" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "common/ssm/terraform.tfstate"
    region = local.tf_state_region
  }
}

# ============================================================================
# VPC 참조
# ============================================================================
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "prod/network/terraform.tfstate"
    region = local.tf_state_region
  }
}
