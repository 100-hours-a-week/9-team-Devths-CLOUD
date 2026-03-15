# ============================================================================
# NAT 구성 로컬 변수
# ============================================================================

# 하위 호환성 처리
locals {
  # enable_nat_gateway가 설정되어 있으면 그것 사용, 아니면 nat_type 사용
  actual_nat_type   = var.enable_nat_gateway != null ? (var.enable_nat_gateway ? "gateway" : "none") : var.nat_type
  actual_single_nat = var.single_nat_gateway != null ? var.single_nat_gateway : var.single_nat

  nat_count = local.actual_nat_type == "none" ? 0 : (local.actual_single_nat ? 1 : length(var.availability_zones))
}
