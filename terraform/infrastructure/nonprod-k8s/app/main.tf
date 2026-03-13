# ============================================================================
# NonProd-k8s APP
# ============================================================================

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "devths-state-terraform"
    key     = "nonprod-k8s/app/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }

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
  tf_state_bucket         = var.tf_state_bucket
  tf_state_region         = var.tf_state_region
  cluster_name            = coalesce(var.cluster_name, "${var.project_name}-${var.environment}")
  control_plane_name      = coalesce(var.instance_name, "${var.project_name}-${var.infra_version}-${var.environment}-k8s-master")
  selected_private_subnet = data.terraform_remote_state.network.outputs.private_subnet_ids[var.private_subnet_index]

  # Security Group 관리
  network_k8s_master_security_group_id = try(data.terraform_remote_state.network.outputs.k8s_master_security_group_id, null)
  network_k8s_worker_security_group_id = try(data.terraform_remote_state.network.outputs.k8s_worker_security_group_id, null)
  use_network_managed_master_sg        = local.network_k8s_master_security_group_id != null
  use_network_managed_worker_sg        = local.network_k8s_worker_security_group_id != null

  # IAM & SSM
  iam_name_suffix       = replace(title(var.environment), "-", "")
  join_command_ssm_path = "/${var.project_name}/${var.environment}/k8s/join-command"
}

# ============================================================================
# State 관리
# ============================================================================

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "nonprod-k8s/network/terraform.tfstate"
    region = local.tf_state_region
  }
}

data "terraform_remote_state" "ssm" {
  backend = "s3"
  config = {
    bucket = local.tf_state_bucket
    key    = "common/ssm/terraform.tfstate"
    region = local.tf_state_region
  }
}




