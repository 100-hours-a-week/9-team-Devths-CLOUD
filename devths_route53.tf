# Route53 호스팅 영역 데이터 소스 (기존 도메인 사용 시)
data "aws_route53_zone" "devths_prod" {
  name         = var.domain_name
  private_zone = false
}

# A 레코드 - 프런트엔드 연결
resource "aws_route53_record" "devths_prod_www" {
  zone_id = data.aws_route53_zone.devths_prod.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.devths_prod_app_eip.public_ip]
}

# A 레코드 - 백엔드 연결
resource "aws_route53_record" "devths_prod_api" {
  zone_id = data.aws_route53_zone.devths_prod.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.devths_prod_app_eip.public_ip]
}

# A 레코드 - 인공지능 연결
resource "aws_route53_record" "devths_prod_ai" {
  zone_id = data.aws_route53_zone.devths_prod.zone_id
  name    = "ai.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.devths_prod_app_eip.public_ip]
}

