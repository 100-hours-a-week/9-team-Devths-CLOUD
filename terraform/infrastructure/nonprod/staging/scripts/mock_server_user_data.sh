#!/bin/bash
# Mock 서버 자동 시작 스크립트

set -e

# 로그 파일 설정
LOG_FILE="/var/log/mock-server-init.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "==============================================="
echo "Mock Server Initialization Started"
echo "Date: $(date)"
echo "==============================================="

# 1. 시스템 패키지 업데이트
echo "[1/7] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release awscli jq \
    ca-certificates apt-transport-https unzip

# 2. Docker 설치
echo "[2/7] Installing Docker Engine..."
# Docker 공식 GPG 키 추가
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker 리포지토리 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 패키지 설치
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 활성화
systemctl enable docker
systemctl start docker

# ubuntu 사용자를 docker 그룹에 추가
usermod -aG docker ubuntu

# Docker 버전 확인
docker --version
docker compose version

# 3. SSM Agent 설치
echo "[3/7] Installing SSM Agent..."
cd /tmp
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb -O amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
apt-get install -f -y
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
rm amazon-ssm-agent.deb

# 4. Mock 서버 코드 다운로드
echo "[4/7] Downloading mock bundle from S3..."
MOCK_DIR="/home/ubuntu/mock"
MOCK_ARCHIVE="/tmp/mock-server-bundle.zip"
MOCK_BUNDLE_S3_URI="__MOCK_BUNDLE_S3_URI__"
AWS_REGION="__AWS_REGION__"

rm -rf "${MOCK_DIR}"
mkdir -p "${MOCK_DIR}"

aws s3 cp "${MOCK_BUNDLE_S3_URI}" "${MOCK_ARCHIVE}" --region "${AWS_REGION}"
unzip -oq "${MOCK_ARCHIVE}" -d "${MOCK_DIR}"
rm -f "${MOCK_ARCHIVE}"

# 5. 환경 변수 설정 (SSM Parameter Store에서 가져오기)
echo "[5/7] Setting up environment variables from SSM..."
cd "${MOCK_DIR}"

# SSM Parameter에서 Google OAuth2 Credentials 가져오기
# SSM Parameter가 없으면 기본값 사용 (나중에 수동으로 설정 필요)
GOOGLE_CLIENT_ID=$(aws ssm get-parameter --name "/Staging/Mock/GOOGLE_CLIENT_ID" --region "${AWS_REGION}" --query "Parameter.Value" --output text 2>/dev/null || echo "your-google-oauth2-client-id")
GOOGLE_CLIENT_SECRET=$(aws ssm get-parameter --name "/Staging/Mock/GOOGLE_CLIENT_SECRET" --with-decryption --region "${AWS_REGION}" --query "Parameter.Value" --output text 2>/dev/null || echo "your-google-oauth2-client-secret")

# .env-old.bk.stg 파일 생성
cat > .env <<EOF
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
EOF

chmod 600 .env

# 6. Mock 서버 시작
echo "[6/7] Starting Mock servers..."
docker compose up -d

# 서비스 시작 대기
sleep 10

# 7. 헬스 체크
echo "[7/7] Health check..."
# WireMock 헬스 체크
if curl -f http://localhost:8082/__admin/health >/dev/null 2>&1; then
    echo "✓ WireMock is healthy"
else
    echo "⚠ WireMock health check failed"
fi

# 소유권 설정
chown -R ubuntu:ubuntu "${MOCK_DIR}"

# 타임존 설정
timedatectl set-timezone Asia/Seoul

echo "==============================================="
echo "Mock Server Initialization Completed"
echo "Date: $(date)"
echo "WireMock: http://$(hostname -I | awk '{print $1}'):8082"
echo "Log: ${LOG_FILE}"
echo "==============================================="
