#!/bin/bash
# SSM Parameter Store에서 모니터링 환경변수를 가져와 .env 파일 생성
# 경로 규칙: /{Env}/{Service}/{VAR} (프로젝트 공통 계층 방식)
#   - /Dev/Monitoring/ : nonprod 모니터링 EC2 (Dev + Stg 동시 관리)
#   - /Prod/Monitoring/: prod 모니터링 EC2 (별도)
#
# 사용법: ./setup-env.sh
# 실행 위치: monitoring/nonprod/ (EC2에서 repo clone 후)

set -e

REGION="ap-northeast-2"
SSM_PREFIX="/Dev/Monitoring"

echo "SSM Parameter Store에서 값 가져오는 중... (prefix: ${SSM_PREFIX})"

GF_USER=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/GF_USER" \
  --with-decryption \
  --query "Parameter.Value" --output text --region $REGION)

GF_PASSWORD=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/GF_PASSWORD" \
  --with-decryption \
  --query "Parameter.Value" --output text --region $REGION)

GF_URL=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/GF_URL" \
  --query "Parameter.Value" --output text --region $REGION)

GF_DOMAIN=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/GF_DOMAIN" \
  --query "Parameter.Value" --output text --region $REGION)

DISCORD_WEBHOOK_NONPROD=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/DISCORD_WEBHOOK_NONPROD" \
  --with-decryption \
  --query "Parameter.Value" --output text --region $REGION)

# .env 파일 생성
cat > .env <<EOF
# 자동 생성 — setup-env.sh ($(date '+%Y-%m-%d %H:%M:%S'))
# 수동 수정 금지: 재실행 시 덮어씌워짐

GF_USER=${GF_USER}
GF_PASSWORD=${GF_PASSWORD}
GF_URL=${GF_URL}
GF_DOMAIN=${GF_DOMAIN}
DISCORD_WEBHOOK_NONPROD=${DISCORD_WEBHOOK_NONPROD}
EOF

echo ".env 파일 생성 완료"
echo "  GF_USER: ${GF_USER}"
echo "  GF_URL: ${GF_URL}"
echo "  GF_DOMAIN: ${GF_DOMAIN}"
echo "  GF_PASSWORD: (hidden)"
echo "  DISCORD_WEBHOOK_NONPROD: (hidden)"
