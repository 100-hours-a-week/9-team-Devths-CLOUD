# ============================================================================
# Security Group Rules
# ============================================================================

# Monitoring 서버가 Dev 환경의 서비스들 (FE, BE, AI)에서 Node Exporter (9100)에 접근할 수 있도록 허용

# Frontend (Next.js) - Node Exporter
resource "aws_security_group_rule" "fe_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.fe_security_group_id
  description              = "Node Exporter from monitoring server"
}

# Backend (Spring Boot) - Node Exporter
resource "aws_security_group_rule" "be_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.be_security_group_id
  description              = "Node Exporter from monitoring server"
}

# Backend (Spring Boot) - Application Metrics (Prometheus)
resource "aws_security_group_rule" "be_app_metrics" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.be_security_group_id
  description              = "Spring Boot metrics from monitoring server"
}

# AI (FastAPI) - Node Exporter
resource "aws_security_group_rule" "ai_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.ai_security_group_id
  description              = "Node Exporter from monitoring server"
}