# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Service 이름 매핑 (CodeDeploy 태그와 일치시키기 위해)
  service_name_map = {
    "fe"      = "Frontend"
    "be"      = "Backend"
    "ai"      = "Ai"
    "mock"    = "Mock"
    "monitor" = "Monitor"
    "all"     = "All"
  }
  service_name = lookup(local.service_name_map, var.service_type, "Unknown")

  default_user_data_base64 = base64encode(join("\n", [
    "#!/bin/bash",
    file("${path.module}/scripts/user_data.sh"),
    file("${path.module}/scripts/install_node_exporter.sh")
  ]))
  launch_template_user_data = var.custom_user_data_base64 != null ? var.custom_user_data_base64 : local.default_user_data_base64

  # ASG에서 인스턴스로 전파할 태그
  asg_propagated_tags = merge(
    var.common_tags,
    {
      Name        = var.asg_name
      Environment = var.environment
      Service     = local.service_name
      ManagedBy   = "Terraform"
    }
  )
}
