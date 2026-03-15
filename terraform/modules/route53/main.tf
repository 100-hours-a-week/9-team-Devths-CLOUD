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

# A 레코드 - 루트 또는 환경별 서브도메인 (가중치 기반 라우팅)
# V1: 기존 EC2 인스턴스
resource "aws_route53_record" "root_v1" {
  count = var.create_root_record && var.enable_weighted_routing && var.create_v1_weighted_records && var.v1_instance_ip != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.base_domain
  type    = "A"
  ttl     = 60

  set_identifier = "V1-Instance"

  weighted_routing_policy {
    weight = var.v1_weight
  }

  records = [var.v1_instance_ip]
}

# V2: 새로운 ALB (ASG 타겟팅)
resource "aws_route53_record" "root_v2" {
  count = var.create_root_record && var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.base_domain
  type    = "A"

  set_identifier = "V2-ALB"

  weighted_routing_policy {
    weight = var.v2_weight
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# 가중치 라우팅이 비활성화된 경우 단일 ALB 레코드
resource "aws_route53_record" "root" {
  count = var.create_root_record && !var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.base_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# A 레코드 - www 서브도메인 (prod only, 가중치 기반 라우팅)
# V1: 기존 EC2 인스턴스
resource "aws_route53_record" "www_v1" {
  count = var.create_www_record && var.subdomain_prefix == "" && var.enable_weighted_routing && var.create_v1_weighted_records && var.v1_instance_ip != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 60

  set_identifier = "V1-Instance"

  weighted_routing_policy {
    weight = var.v1_weight
  }

  records = [var.v1_instance_ip]
}

# V2: 새로운 ALB (ASG 타겟팅)
resource "aws_route53_record" "www_v2" {
  count = var.create_www_record && var.subdomain_prefix == "" && var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  set_identifier = "V2-ALB"

  weighted_routing_policy {
    weight = var.v2_weight
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# 가중치 라우팅이 비활성화된 경우 단일 ALB 레코드
resource "aws_route53_record" "www" {
  count = var.create_www_record && var.subdomain_prefix == "" && !var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# A 레코드 - api 서브도메인 (백엔드, 가중치 기반 라우팅)
# V1: 기존 EC2 인스턴스
resource "aws_route53_record" "api_v1" {
  count = var.create_api_record && var.enable_weighted_routing && var.create_v1_weighted_records && var.v1_instance_ip != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.api_domain
  type    = "A"
  ttl     = 60

  set_identifier = "V1-Instance"

  weighted_routing_policy {
    weight = var.v1_weight
  }

  records = [var.v1_instance_ip]
}

# V2: 새로운 ALB (ASG 타겟팅)
resource "aws_route53_record" "api_v2" {
  count = var.create_api_record && var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.api_domain
  type    = "A"

  set_identifier = "V2-ALB"

  weighted_routing_policy {
    weight = var.v2_weight
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# 가중치 라우팅이 비활성화된 경우 단일 ALB 레코드
resource "aws_route53_record" "api" {
  count = var.create_api_record && !var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# A 레코드 - ai 서브도메인 (가중치 기반 라우팅)
# V1: 기존 EC2 인스턴스
resource "aws_route53_record" "ai_v1" {
  count = var.create_ai_record && var.enable_weighted_routing && var.create_v1_weighted_records && var.v1_instance_ip != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.ai_domain
  type    = "A"
  ttl     = 60

  set_identifier = "V1-Instance"

  weighted_routing_policy {
    weight = var.v1_weight
  }

  records = [var.v1_instance_ip]
}

# V2: 새로운 ALB (ASG 타겟팅)
resource "aws_route53_record" "ai_v2" {
  count = var.create_ai_record && var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.ai_domain
  type    = "A"

  set_identifier = "V2-ALB"

  weighted_routing_policy {
    weight = var.v2_weight
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# 가중치 라우팅이 비활성화된 경우 단일 ALB 레코드
resource "aws_route53_record" "ai" {
  count = var.create_ai_record && !var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.ai_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# A 레코드 - monitoring 서브도메인 (가중치 기반 라우팅)
# V1: 기존 EC2 인스턴스 (선택)
resource "aws_route53_record" "monitoring_v1" {
  count = var.create_monitoring_record && var.enable_weighted_routing && var.create_v1_weighted_records && var.v1_instance_ip != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.monitoring_domain
  type    = "A"
  ttl     = 60

  set_identifier = "V1-Instance"

  weighted_routing_policy {
    weight = var.v1_weight
  }

  records = [var.v1_instance_ip]
}

# V2: 새로운 ALB
resource "aws_route53_record" "monitoring_v2" {
  count = var.create_monitoring_record && var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.monitoring_domain
  type    = "A"

  set_identifier = "V2-ALB"

  weighted_routing_policy {
    weight = var.v2_weight
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# 가중치 라우팅이 비활성화된 경우 단일 ALB 레코드
resource "aws_route53_record" "monitoring" {
  count = var.create_monitoring_record && !var.enable_weighted_routing ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.monitoring_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}
