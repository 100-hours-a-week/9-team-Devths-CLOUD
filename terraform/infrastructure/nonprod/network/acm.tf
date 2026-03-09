# ============================================================================
# ACM
# ============================================================================

# Dev 환경 인증서 (dev.devths.com)
data "aws_acm_certificate" "dev" {
  domain      = "dev.devths.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

# Staging 환경 인증서 (stg.devths.com)
data "aws_acm_certificate" "stg" {
  domain      = "stg.devths.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

# Dev Monitoring 인증서 (dev.monitoring.devths.com)
data "aws_acm_certificate" "dev_monitoring" {
  domain      = "dev.monitoring.devths.com"
  statuses    = ["ISSUED"]
  most_recent = true
}
