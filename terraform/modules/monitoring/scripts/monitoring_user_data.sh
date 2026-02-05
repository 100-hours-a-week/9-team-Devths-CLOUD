#!/bin/bash

################################################################################
# Monitoring Server User Data Script
# 용도: Prometheus + Grafana 모니터링 서버 초기 설정
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
# 1. 시스템 업데이트
################################################################################

log_info "Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

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
# 3. Nginx 설치
################################################################################

log_info "Installing Nginx and Certbot..."

apt-get install -y nginx certbot python3-certbot-nginx

# Nginx 시작 및 자동 시작 설정
systemctl start nginx
systemctl enable nginx

log_info "Nginx installed successfully"

################################################################################
# 4. 모니터링 디렉토리 생성
################################################################################

log_info "Creating monitoring directory structure..."

MONITORING_DIR="/home/ubuntu/monitoring"
mkdir -p $MONITORING_DIR
cd $MONITORING_DIR

# 환경별 디렉토리 생성
%{ if environment == "nonprod" ~}
mkdir -p non-prod/{prometheus/alerts,grafana/provisioning/datasources}
ENVIRONMENT_DIR="$MONITORING_DIR/non-prod"
%{ else ~}
mkdir -p prod/{prometheus/alerts,grafana/provisioning/datasources}
ENVIRONMENT_DIR="$MONITORING_DIR/prod"
%{ endif ~}

################################################################################
# 5. Docker Compose 파일 생성
################################################################################

log_info "Creating Docker Compose configuration..."

cat > $ENVIRONMENT_DIR/docker-compose.yml <<'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-${environment}
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=${prometheus_retention}'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts:/etc/prometheus/alerts:ro
      - prometheus-data:/prometheus
    networks:
      - monitoring
    extra_hosts:
      - "host.docker.internal:host-gateway"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana-${environment}
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${grafana_admin_password}
      - GF_SERVER_ROOT_URL=https://${monitoring_domain}
      - GF_SERVER_DOMAIN=${monitoring_domain}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
%{ if environment == "prod" ~}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_AUTH_ANONYMOUS_ENABLED=false
%{ endif ~}
    ports:
      - "3001:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring
    depends_on:
      - prometheus

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local

networks:
  monitoring:
    driver: bridge
DOCKER_COMPOSE_EOF

log_info "Docker Compose file created"

################################################################################
# 6. Prometheus 설정 파일 생성
################################################################################

log_info "Creating Prometheus configuration..."

cat > $ENVIRONMENT_DIR/prometheus/prometheus.yml <<'PROMETHEUS_EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'devths-${environment}'
    region: 'ap-northeast-2'

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - '/etc/prometheus/alerts/*.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          env: '${environment}'
          service: 'prometheus'

%{ if environment == "nonprod" ~}
  # Dev Environment - Node Exporter
  - job_name: 'node-exporter-dev'
    static_configs:
      - targets: ['${target_dev_ip}:9100']
        labels:
          env: 'dev'
          service: 'node-exporter'
          instance_name: 'devths-v1-dev'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # Dev Environment - Nginx Exporter
  - job_name: 'nginx-exporter-dev'
    static_configs:
      - targets: ['${target_dev_ip}:9113']
        labels:
          env: 'dev'
          service: 'nginx-exporter'
          instance_name: 'devths-v1-dev'

  # Staging Environment - Node Exporter
  - job_name: 'node-exporter-staging'
    static_configs:
      - targets: ['${target_staging_ip}:9100']
        labels:
          env: 'staging'
          service: 'node-exporter'
          instance_name: 'devths-v1-stg'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # Staging Environment - Nginx Exporter
  - job_name: 'nginx-exporter-staging'
    static_configs:
      - targets: ['${target_staging_ip}:9113']
        labels:
          env: 'staging'
          service: 'nginx-exporter'
          instance_name: 'devths-v1-stg'
%{ else ~}
  # Production Environment - Node Exporter
  - job_name: 'node-exporter-prod'
    static_configs:
      - targets: ['${target_prod_ip}:9100']
        labels:
          env: 'prod'
          service: 'node-exporter'
          instance_name: 'devths-v1-prod'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # Production Environment - Nginx Exporter
  - job_name: 'nginx-exporter-prod'
    static_configs:
      - targets: ['${target_prod_ip}:9113']
        labels:
          env: 'prod'
          service: 'nginx-exporter'
          instance_name: 'devths-v1-prod'
%{ endif ~}
PROMETHEUS_EOF

log_info "Prometheus configuration created"

################################################################################
# 7. Prometheus Alert Rules 생성
################################################################################

log_info "Creating Prometheus alert rules..."

%{ if environment == "nonprod" ~}
# Non-Prod Alert Rules
cat > $ENVIRONMENT_DIR/prometheus/alerts/alert-rules.yml <<'ALERT_RULES_EOF'
groups:
  - name: http_errors
    interval: 30s
    rules:
      - alert: HighHttp5xxErrorRate
        expr: |
          rate(nginx_http_requests_total{status=~"5.."}[5m]) * 300 > 10
        for: 2m
        labels:
          severity: critical
          category: http
        annotations:
          summary: "High 5xx error rate detected on {{ $labels.instance }}"
          description: "{{ $labels.env }} environment is experiencing {{ $value }} 5xx errors in the last 5 minutes"

      - alert: HighHttp5xxErrorPercentage
        expr: |
          (
            sum by (env, instance) (rate(nginx_http_requests_total{status=~"5.."}[5m]))
            /
            sum by (env, instance) (rate(nginx_http_requests_total[5m]))
          ) * 100 > 5
        for: 3m
        labels:
          severity: warning
          category: http
        annotations:
          summary: "High 5xx error percentage on {{ $labels.instance }}"
          description: "{{ $labels.env }} has {{ $value | humanizePercentage }} 5xx error rate"

  - name: system_resources
    interval: 30s
    rules:
      - alert: HighCpuUsage
        expr: |
          100 - (avg by (env, instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          category: system
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "{{ $labels.env }} CPU usage is {{ $value | humanize }}%"

      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          category: system
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "{{ $labels.env }} memory usage is {{ $value | humanize }}%"

  - name: service_health
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
          category: availability
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.env }} instance has been down for more than 2 minutes"
ALERT_RULES_EOF
%{ else ~}
# Prod Alert Rules (더 엄격한 임계값)
cat > $ENVIRONMENT_DIR/prometheus/alerts/alert-rules.yml <<'ALERT_RULES_EOF'
groups:
  - name: http_errors
    interval: 30s
    rules:
      - alert: HighHttp5xxErrorRate
        expr: |
          rate(nginx_http_requests_total{status=~"5.."}[5m]) * 300 > 5
        for: 1m
        labels:
          severity: critical
          category: http
          environment: production
        annotations:
          summary: "PRODUCTION: High 5xx error rate detected"
          description: "Production is experiencing {{ $value }} 5xx errors in the last 5 minutes"

      - alert: HighHttp5xxErrorPercentage
        expr: |
          (
            sum by (env, instance) (rate(nginx_http_requests_total{status=~"5.."}[5m]))
            /
            sum by (env, instance) (rate(nginx_http_requests_total[5m]))
          ) * 100 > 2
        for: 2m
        labels:
          severity: critical
          category: http
          environment: production
        annotations:
          summary: "PRODUCTION: High 5xx error percentage"
          description: "Production has {{ $value | humanizePercentage }} 5xx error rate"

  - name: system_resources
    interval: 30s
    rules:
      - alert: HighCpuUsage
        expr: |
          100 - (avg by (env, instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 75
        for: 3m
        labels:
          severity: warning
          category: system
          environment: production
        annotations:
          summary: "PRODUCTION: High CPU usage"
          description: "Production CPU usage is {{ $value | humanize }}%"

      - alert: CriticalCpuUsage
        expr: |
          100 - (avg by (env, instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 2m
        labels:
          severity: critical
          category: system
          environment: production
        annotations:
          summary: "PRODUCTION: Critical CPU usage"
          description: "Production CPU usage is {{ $value | humanize }}%"

  - name: service_health
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          category: availability
          environment: production
        annotations:
          summary: "PRODUCTION: Instance is down"
          description: "Production instance has been down for more than 1 minute"
ALERT_RULES_EOF
%{ endif ~}

log_info "Alert rules created"

################################################################################
# 8. Grafana 데이터소스 Provisioning 설정
################################################################################

log_info "Creating Grafana datasource provisioning..."

cat > $ENVIRONMENT_DIR/grafana/provisioning/datasources/datasources.yml <<'GRAFANA_DATASOURCE_EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "15s"
      queryTimeout: "60s"
      httpMethod: POST
GRAFANA_DATASOURCE_EOF

log_info "Grafana datasource provisioning created"

################################################################################
# 9. Nginx 리버스 프록시 설정
################################################################################

log_info "Creating Nginx reverse proxy configuration..."

cat > /etc/nginx/sites-available/grafana-${environment} <<'NGINX_CONFIG_EOF'
upstream grafana_${environment} {
    server 127.0.0.1:3001;
    keepalive 32;
}

server {
    listen 80;
    server_name ${monitoring_domain};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://grafana_${environment};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_CONFIG_EOF

# Nginx 설정 활성화
ln -sf /etc/nginx/sites-available/grafana-${environment} /etc/nginx/sites-enabled/

# Nginx 설정 테스트 및 재시작
nginx -t && systemctl reload nginx

log_info "Nginx reverse proxy configured"

################################################################################
# 10. 디렉토리 권한 설정
################################################################################

log_info "Setting directory permissions..."

chown -R ubuntu:ubuntu $MONITORING_DIR

################################################################################
# 11. Docker Compose 시작
################################################################################

log_info "Starting Docker Compose..."

cd $ENVIRONMENT_DIR
docker compose up -d

# 컨테이너 시작 대기
sleep 10

# 상태 확인
docker compose ps

log_info "Docker Compose started successfully"

################################################################################
# 12. SSL 인증서 발급 (도메인 DNS 설정 후 수동 실행 필요)
################################################################################

log_info "SSL certificate setup information:"
log_info "After DNS is configured, run the following command:"
log_info "sudo certbot --nginx -d ${monitoring_domain} --non-interactive --agree-tos --email admin@devths.com"

# SSL 인증서 발급 시도 (DNS가 설정되어 있을 경우)
# 실패해도 계속 진행
if ! certbot --nginx -d ${monitoring_domain} --non-interactive --agree-tos --email admin@devths.com --redirect; then
    log_warn "SSL certificate provisioning failed. Please run certbot manually after DNS propagation."
fi

################################################################################
# 13. 설정 완료 메시지
################################################################################

echo ""
echo "================================"
echo "Monitoring server setup completed!"
echo "================================"
echo "Environment: ${environment}"
echo "Monitoring Domain: ${monitoring_domain}"
echo "Grafana URL: https://${monitoring_domain}"
echo "Prometheus URL: http://$(hostname -I | awk '{print $1}'):9090"
echo ""
echo "Default Grafana credentials:"
echo "  Username: admin"
echo "  Password: ${grafana_admin_password}"
echo ""
echo "Next steps:"
echo "1. Configure Route53 A record: ${monitoring_domain} -> $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "2. Wait for DNS propagation"
echo "3. SSL certificate will be automatically provisioned or run certbot manually"
echo "4. Install exporters on target servers"
echo "================================"
echo "Setup timestamp: $(date)"
echo "================================"
