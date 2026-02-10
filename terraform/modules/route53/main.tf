# Route53 호스팅 영역 데이터 소스
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# 로컬 변수 - 서브도메인 접두사 계산
locals {
  base_domain       = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.${var.domain_name}" : var.domain_name
  api_domain        = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.api.${var.domain_name}" : "api.${var.domain_name}"
  ai_domain         = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.ai.${var.domain_name}" : "ai.${var.domain_name}"
  monitoring_domain = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.monitoring.${var.domain_name}" : "monitoring.${var.domain_name}"
}

# ========================================
# ALB Alias 레코드
# ========================================

# A 레코드 - 루트 또는 환경별 서브도메인 (ALB Alias)
resource "aws_route53_record" "root" {
  count = var.create_root_record ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.base_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# A 레코드 - www 서브도메인 (prod only, ALB Alias)
resource "aws_route53_record" "www" {
  count = var.create_www_record && var.subdomain_prefix == "" ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# A 레코드 - api 서브도메인 (백엔드, ALB Alias)
resource "aws_route53_record" "api" {
  count = var.create_api_record ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# A 레코드 - ai 서브도메인 (ALB Alias)
resource "aws_route53_record" "ai" {
  count = var.create_ai_record ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.ai_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# A 레코드 - monitoring 서브도메인 (ALB Alias)
resource "aws_route53_record" "monitoring" {
  count = var.create_monitoring_record ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.monitoring_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
