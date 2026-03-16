locals {
  k8s_cluster_name = "${var.project_name}-prod-k8s"
  k8s_name_prefix  = "${var.project_name}-${var.infra_version}-prod-k8s"
}

# ============================================================================
# K8s 마스터 노드 보안그룹
# ============================================================================

resource "aws_security_group" "k8s_master" {
  name        = "${local.k8s_name_prefix}-master-sg"
  description = "Security group for Kubernetes control-plane nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name     = "${local.k8s_name_prefix}-master-sg"
      Cluster  = local.k8s_cluster_name
      Role     = "control-plane"
      Workload = "kubernetes"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# K8s 워커 노드 보안그룹
# ============================================================================

resource "aws_security_group" "k8s_worker" {
  name        = "${local.k8s_name_prefix}-worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name     = "${local.k8s_name_prefix}-worker-sg"
      Cluster  = local.k8s_cluster_name
      Role     = "worker"
      Workload = "kubernetes"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# K8s 마스터 노드 인그레스 규칙
# ============================================================================

resource "aws_vpc_security_group_ingress_rule" "k8s_master_api_server_from_workers" {
  security_group_id            = aws_security_group.k8s_master.id
  referenced_security_group_id = aws_security_group.k8s_worker.id
  description                  = "Kubernetes API server from worker nodes"
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_kubelet_from_workers" {
  security_group_id            = aws_security_group.k8s_master.id
  referenced_security_group_id = aws_security_group.k8s_worker.id
  description                  = "Kubelet API from worker nodes"
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_overlay_from_workers" {
  security_group_id            = aws_security_group.k8s_master.id
  referenced_security_group_id = aws_security_group.k8s_worker.id
  description                  = "Calico overlay traffic from worker nodes"
  from_port                    = var.calico_overlay_udp_port
  to_port                      = var.calico_overlay_udp_port
  ip_protocol                  = "udp"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_intra_control_plane" {
  security_group_id            = aws_security_group.k8s_master.id
  referenced_security_group_id = aws_security_group.k8s_master.id
  description                  = "Intra-control-plane traffic"
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_overlay_from_control_plane" {
  security_group_id            = aws_security_group.k8s_master.id
  referenced_security_group_id = aws_security_group.k8s_master.id
  description                  = "Calico overlay traffic from control-plane nodes"
  from_port                    = var.calico_overlay_udp_port
  to_port                      = var.calico_overlay_udp_port
  ip_protocol                  = "udp"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_http" {
  for_each = toset(var.k8s_ingress_allowed_cidrs)

  security_group_id = aws_security_group.k8s_master.id
  description       = "HTTP to Kubernetes control-plane nodes"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_https" {
  for_each = toset(var.k8s_ingress_allowed_cidrs)

  security_group_id = aws_security_group.k8s_master.id
  description       = "HTTPS to Kubernetes control-plane nodes"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_nodeport" {
  for_each = toset(var.k8s_nodeport_allowed_cidrs)

  security_group_id = aws_security_group.k8s_master.id
  description       = "NodePort access to Kubernetes control-plane nodes"
  from_port         = 30000
  to_port           = 32767
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_api_server_additional" {
  for_each = toset(var.k8s_api_server_allowed_cidrs)

  security_group_id = aws_security_group.k8s_master.id
  description       = "Additional Kubernetes API access"
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "k8s_master_all" {
  security_group_id = aws_security_group.k8s_master.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# K8s 워커 노드 인그레스 규칙
# ============================================================================

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_http" {
  for_each = toset(var.k8s_ingress_allowed_cidrs)

  security_group_id = aws_security_group.k8s_worker.id
  description       = "HTTP to Kubernetes worker nodes"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_https" {
  for_each = toset(var.k8s_ingress_allowed_cidrs)

  security_group_id = aws_security_group.k8s_worker.id
  description       = "HTTPS to Kubernetes worker nodes"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_nodeport" {
  for_each = toset(var.k8s_nodeport_allowed_cidrs)

  security_group_id = aws_security_group.k8s_worker.id
  description       = "NodePort access to Kubernetes worker nodes"
  from_port         = 30000
  to_port           = 32767
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_kubelet_from_master" {
  security_group_id            = aws_security_group.k8s_worker.id
  referenced_security_group_id = aws_security_group.k8s_master.id
  description                  = "Kubelet API from control-plane nodes"
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_overlay_from_master" {
  security_group_id            = aws_security_group.k8s_worker.id
  referenced_security_group_id = aws_security_group.k8s_master.id
  description                  = "Calico overlay traffic from control-plane nodes"
  from_port                    = var.calico_overlay_udp_port
  to_port                      = var.calico_overlay_udp_port
  ip_protocol                  = "udp"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_overlay_from_workers" {
  security_group_id            = aws_security_group.k8s_worker.id
  referenced_security_group_id = aws_security_group.k8s_worker.id
  description                  = "Calico overlay traffic from worker nodes"
  from_port                    = var.calico_overlay_udp_port
  to_port                      = var.calico_overlay_udp_port
  ip_protocol                  = "udp"
}

resource "aws_vpc_security_group_egress_rule" "k8s_worker_all" {
  security_group_id = aws_security_group.k8s_worker.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
