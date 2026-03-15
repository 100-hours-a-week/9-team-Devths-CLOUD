# ============================================================================
# Master Security Group
# ============================================================================
# Fall back to a locally managed SG until the network stack publishes the
# dedicated Kubernetes security group outputs.
module "master_security_group" {
  count  = local.use_network_managed_master_sg ? 0 : 1
  source = "../../../modules/security-group"

  security_group_name      = "${var.project_name}-${var.infra_version}-${var.environment}-k8s-master-sg"
  description              = "Security group for the Kubernetes control-plane node"
  vpc_id                   = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                 = data.terraform_remote_state.network.outputs.vpc_cidr
  cluster_name             = local.cluster_name
  api_server_allowed_cidrs = var.api_server_allowed_cidrs
  tags                     = var.common_tags
}

# ============================================================================
# Worker Security Group
# ============================================================================
module "worker_security_group" {
  count  = local.use_network_managed_worker_sg ? 0 : 1
  source = "../../../modules/security-group"

  security_group_name      = "${var.project_name}-${var.infra_version}-${var.environment}-k8s-worker-sg"
  description              = "Security group for the Kubernetes worker nodes"
  vpc_id                   = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                 = data.terraform_remote_state.network.outputs.vpc_cidr
  cluster_name             = local.cluster_name
  api_server_allowed_cidrs = []
  tags                     = var.common_tags
}
