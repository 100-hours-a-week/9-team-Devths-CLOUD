#!/bin/bash

################################################################################
# Monitoring Server User Data Script
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
# 4. 모니터링 디렉토리 생성
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
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring
    depends_on:
      - prometheus

  loki:
    image: grafana/loki:latest
    container_name: loki-${environment}
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    container_name: promtail-${environment}
    restart: unless-stopped
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/log:/var/log:ro
      - ./promtail/config.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring
    depends_on:
      - loki

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
  loki-data:
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

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: false
    editable: true
    jsonData:
      maxLines: 1000
      derivedFields:
        - datasourceUid: Prometheus
          matcherRegex: "traceID=(\\w+)"
          name: TraceID
          url: '$${__value.raw}'
GRAFANA_DATASOURCE_EOF

log_info "Grafana datasource provisioning created"

################################################################################
# 9. Loki 설정 파일 생성
################################################################################

log_info "Creating Loki configuration..."

cat > $ENVIRONMENT_DIR/loki/loki-config.yml <<'LOKI_CONFIG_EOF'
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

limits_config:
  retention_period: ${prometheus_retention}
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  per_stream_rate_limit: 10MB
  per_stream_rate_limit_burst: 20MB

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: ${prometheus_retention}

compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
LOKI_CONFIG_EOF

log_info "Loki configuration created"

################################################################################
# 10. Promtail 설정 파일 생성
################################################################################

log_info "Creating Promtail configuration..."

cat > $ENVIRONMENT_DIR/promtail/config.yml <<'PROMTAIL_CONFIG_EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Docker 컨테이너 로그
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*.log

    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            attrs:
      - labels:
          stream:
      - output:
          source: output

  # 시스템 로그
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: system
          __path__: /var/log/*.log

  # Nginx 로그
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/*.log

    pipeline_stages:
      - regex:
          expression: '^(?P<remote_addr>[\w\.]+) - (?P<remote_user>[\w]+) \[(?P<time_local>.*?)\] "(?P<method>\w+) (?P<request>.*?) (?P<protocol>.*?)" (?P<status>[\d]+) (?P<body_bytes_sent>[\d]+) "(?P<http_referer>.*?)" "(?P<http_user_agent>.*?)"'
      - labels:
          method:
          status:

  # User data 설치 로그
  - job_name: userdata
    static_configs:
      - targets:
          - localhost
        labels:
          job: userdata
          __path__: /var/log/user-data.log

%{ if environment == "nonprod" ~}
  # Dev 환경 애플리케이션 로그
  - job_name: app-dev
    static_configs:
      - targets:
          - localhost
        labels:
          job: application
          environment: dev
          __path__: /var/log/app-dev/*.log
%{ else ~}
  # Prod 환경 애플리케이션 로그
  - job_name: app-prod
    static_configs:
      - targets:
          - localhost
        labels:
          job: application
          environment: prod
          __path__: /var/log/app-prod/*.log
%{ endif ~}
PROMTAIL_CONFIG_EOF

log_info "Promtail configuration created"

################################################################################
# 11. 디렉토리 권한 설정
################################################################################

log_info "Setting directory permissions..."

chown -R ubuntu:ubuntu $MONITORING_DIR

################################################################################
# 12. Docker Compose 시작
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
# 13. 완료 메시지
################################################################################

echo ""
echo "================================"
echo "Monitoring Server Setup Complete!"
echo "================================"
echo ""
echo "Services:"
echo "  - Grafana:    https://${monitoring_domain}"
echo "  - Prometheus: http://localhost:9090"
echo "  - Loki:       http://localhost:3100"
echo "  - Promtail:   http://localhost:9080"
echo ""
echo "Grafana credentials:"
echo "  Username: admin"
echo "  Password: ${grafana_admin_password}"
echo ""
echo "Container status:"
docker compose ps
echo ""
echo "Logs location: /var/log/user-data.log"
echo "Monitoring directory: $MONITORING_DIR"
echo ""
log_info "Setup completed successfully at $(date)"