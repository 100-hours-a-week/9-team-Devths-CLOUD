# ============================================================================
# Security Group Rules
# ============================================================================

# Security Group 업데이트
resource "aws_security_group_rule" "dev_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.ec2_security_group_id
  description              = "Node Exporter from monitoring server"
}