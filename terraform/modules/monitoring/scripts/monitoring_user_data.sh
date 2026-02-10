#!/bin/bash

################################################################################
# Monitoring Server User Data Script
# 용도: Prometheus + Grafana + Loki + Promtail 모니터링 서버 초기 설정
# 환경: ${environment}
# 도메인: ${monitoring_domain}
################################################################################

set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "================================"
echo "Starting monitoring server setup for ${environment} environment"
echo "Timestamp: $(date)"
echo "================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "$${GREEN}[INFO]$${NC} $1"
}

log_warn() {
    echo -e "$${YELLOW}[WARN]$${NC} $1"
}

log_error() {
    echo -e "$${RED}[ERROR]$${NC} $1"
}

################################################################################
# 1. 시스템 업데이트 및 필수 패키지 설치
################################################################################

log_info "Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release \
    awscli jq ca-certificates apt-transport-https

################################################################################
# 2. Docker 설치
################################################################################

log_info "Installing Docker..."

# Docker GPG key 추가
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker repository 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 자동 시작 설정
systemctl start docker
systemctl enable docker

# ubuntu 사용자를 docker 그룹에 추가
usermod -aG docker ubuntu

log_info "Docker installed successfully"
docker --version
docker compose version

################################################################################
# 3. 모니터링 디렉토리 생성
################################################################################

log_info "Creating monitoring directory structure..."

MONITORING_DIR="/home/ubuntu/monitoring"
mkdir -p $MONITORING_DIR
cd $MONITORING_DIR

# 환경별 디렉토리 생성
%{ if environment == "nonprod" ~}
mkdir -p non-prod/{prometheus/alerts,grafana/provisioning/datasources,loki,promtail}
ENVIRONMENT_DIR="$MONITORING_DIR/non-prod"
%{ else ~}
mkdir -p prod/{prometheus/alerts,grafana/provisioning/datasources,loki,promtail}
ENVIRONMENT_DIR="$MONITORING_DIR/prod"
%{ endif ~}

################################################################################
# 4. 설정 파일 생성
################################################################################

log_info "Creating configuration files..."

# Docker Compose
cat > $ENVIRONMENT_DIR/docker-compose.yml <<'EOF'
${docker_compose_content}
EOF

# Prometheus
cat > $ENVIRONMENT_DIR/prometheus/prometheus.yml <<'EOF'
${prometheus_content}
EOF

# Prometheus Alert Rules
cat > $ENVIRONMENT_DIR/prometheus/alerts/alert-rules.yml <<'EOF'
${alert_rules_content}
EOF

# Loki
cat > $ENVIRONMENT_DIR/loki/loki-config.yml <<'EOF'
${loki_content}
EOF

# Promtail
cat > $ENVIRONMENT_DIR/promtail/config.yml <<'EOF'
${promtail_content}
EOF

# Grafana Datasources
cat > $ENVIRONMENT_DIR/grafana/provisioning/datasources/datasources.yml <<'EOF'
${grafana_datasources_content}
EOF

log_info "Configuration files created"

################################################################################
# 5. 디렉토리 권한 설정
################################################################################

log_info "Setting directory permissions..."

chown -R ubuntu:ubuntu $MONITORING_DIR

################################################################################
# 6. Docker Compose 시작
################################################################################

log_info "Starting Docker Compose..."

cd $ENVIRONMENT_DIR
docker compose up -d

# 컨테이너 시작 대기
sleep 10

# 상태 확인
docker compose ps

log_info "Docker Compose started successfully"

# SSM Agent 설치 및 시작 (Ubuntu 22.04 전용)
echo "SSM Agent 설정 시작..."

# 1. snap을 통해 amazon-ssm-agent 설치 여부 확인 및 설치
if ! snap list amazon-ssm-agent > /dev/null 2>&1; then
    echo "SSM Agent 설치 중..."
    sudo snap install amazon-ssm-agent --classic
else
    echo "SSM Agent가 이미 설치되어 있습니다."
fi

# 2. 서비스 시작 및 활성화
echo "SSM Agent 서비스 시작 중..."
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent

# 3. 상태 확인
echo "------------------------------------------"
snap list amazon-ssm-agent
echo "✓ SSM Agent 설정 완료"
echo "------------------------------------------"

################################################################################
# 7. 완료 메시지
################################################################################

echo ""
echo "================================"
echo "Monitoring Server Setup Complete!"
echo "================================"