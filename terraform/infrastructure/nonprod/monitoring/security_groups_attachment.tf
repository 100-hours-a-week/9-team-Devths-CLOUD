# ============================================================================
# Security Group Rules
# ============================================================================

# ============================================================================
# 프런트엔드
# ============================================================================
# Node Exporter ()
resource "aws_security_group_rule" "fe_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.fe_security_group_id
  description              = "Node Exporter from monitoring server"
}

# Frontend (Next.js) - Application Metrics (Prometheus)
resource "aws_security_group_rule" "fe_app_metrics" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.fe_security_group_id
  description              = "Next Js metrics from monitoring server"
}


# ============================================================================
# 백엔드
# ============================================================================
# Node Exporter ()
resource "aws_security_group_rule" "be_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.be_security_group_id
  description              = "Node Exporter from monitoring server"
}

# 스프링부트 프로메테우스 ()
resource "aws_security_group_rule" "be_app_metrics" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.be_security_group_id
  description              = "Spring Boot metrics from monitoring server"
}

# ============================================================================
# 인공지능
# ============================================================================
# Node Exporter ()
resource "aws_security_group_rule" "ai_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.ai_security_group_id
  description              = "Node Exporter from monitoring server"
}

# AI ASG - Application Metrics (Prometheus)
resource "aws_security_group_rule" "ai_asg_app_metrics" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = module.monitoring.security_group_id
  security_group_id        = data.terraform_remote_state.vpc.outputs.ai_security_group_id
  description              = "FastAPI metrics from monitoring server"
}

# ============================================================================
# Monitoring 서버 인바운드 규칙 (서비스 → Monitoring)
# ============================================================================

# Backend → Tempo (OTLP gRPC for tracing data)
resource "aws_security_group_rule" "monitoring_tempo_from_be" {
  type                     = "ingress"
  from_port                = 4318
  to_port                  = 4318
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.vpc.outputs.be_security_group_id
  security_group_id        = module.monitoring.security_group_id
  description              = "TempoData from BE"
}