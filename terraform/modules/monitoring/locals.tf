# 환경별 도메인 설정을 위한 로컬 변수
locals {
  # 모니터링 도메인 (nonprod: monitoring.dev.devths.com, prod: monitoring.devths.com)
  monitoring_domain = var.environment == "prod" ? "monitoring.${var.domain_name}" : "monitoring.dev.${var.domain_name}"

  # Prometheus 데이터 보존 기간
  prometheus_retention = var.environment == "prod" ? "90d" : "30d"

  # 서버 레이블
  server_label = var.environment == "prod" ? "운영 모니터링 서버" : "개발 모니터링 서버"
}
