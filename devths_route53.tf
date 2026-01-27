# Route53 호스팅 영역 데이터 소스 (기존 도메인 사용 시)
data "aws_route53_zone" "devths_prod" {
  name         = "devths.com"  # 실제 도메인으로 변경
  private_zone = false
}

# A 레코드 - 프런트엔드 연결
resource "aws_route53_record" "devths_prod_app" {
  zone_id = data.aws_route53_zone.devths_prod.zone_id
  name    = "www.devths.com"  # 서브도메인으로 변경
  type    = "A"
  ttl     = 300
  records = [aws_eip.devths_prod_app_eip.public_ip]
}

# A 레코드 - 백엔드 연결
resource "aws_route53_record" "devths_prod_app" {
  zone_id = data.aws_route53_zone.devths_prod.zone_id
  name    = "api.devths.com"  # 서브도메인으로 변경
  type    = "A"
  ttl     = 300
  records = [aws_eip.devths_prod_app_eip.public_ip]
}

# A 레코드 - 인공지능 연결
resource "aws_route53_record" "devths_prod_app" {
  zone_id = data.aws_route53_zone.devths_prod.zone_id
  name    = "ai.devths.com"  # 서브도메인으로 변경
  type    = "A"
  ttl     = 300
  records = [aws_eip.devths_prod_app_eip.public_ip]
}

