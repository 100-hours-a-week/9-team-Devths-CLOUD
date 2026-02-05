#!/bin/bash

################################################################################
# Prometheus Exporters 설치 스크립트
# 대상: API EC2 인스턴스 (Dev, Staging, Prod)
# 설치 항목: node_exporter, nginx-prometheus-exporter
################################################################################

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root 권한 확인
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# 버전 정의
NODE_EXPORTER_VERSION="1.7.0"
NGINX_EXPORTER_VERSION="1.1.0"

# 아키텍처 감지
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log_info "Detected architecture: $ARCH"

################################################################################
# 1. Node Exporter 설치
################################################################################

install_node_exporter() {
    log_info "Installing Node Exporter v${NODE_EXPORTER_VERSION}..."

    # 다운로드 디렉토리 생성
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Node Exporter 다운로드
    DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
    log_info "Downloading from: $DOWNLOAD_URL"

    if ! curl -L -O "$DOWNLOAD_URL"; then
        log_error "Failed to download Node Exporter"
        exit 1
    fi

    # 압축 해제
    tar xvf "node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"

    # 바이너리 복사
    cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/
    chmod +x /usr/local/bin/node_exporter

    # node_exporter 사용자 생성
    if ! id -u node_exporter > /dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false node_exporter
        log_info "Created node_exporter user"
    fi

    # systemd 서비스 파일 생성
    cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \\
    --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)(\$|/) \\
    --collector.netclass.ignored-devices=^(veth.*|docker.*|br-.*)$ \\
    --collector.netdev.device-exclude=^(veth.*|docker.*|br-.*)$

[Install]
WantedBy=multi-user.target
EOF

    # 서비스 활성화 및 시작
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter

    # 정리
    cd /
    rm -rf "$TEMP_DIR"

    log_info "Node Exporter installed and started successfully"
    log_info "Node Exporter is running on port 9100"
}

################################################################################
# 2. Nginx Prometheus Exporter 설치
################################################################################

install_nginx_exporter() {
    log_info "Installing Nginx Prometheus Exporter v${NGINX_EXPORTER_VERSION}..."

    # 다운로드 디렉토리 생성
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Nginx Exporter 다운로드
    DOWNLOAD_URL="https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_${ARCH}.tar.gz"
    log_info "Downloading from: $DOWNLOAD_URL"

    if ! curl -L -O "$DOWNLOAD_URL"; then
        log_error "Failed to download Nginx Exporter"
        exit 1
    fi

    # 압축 해제
    tar xvf "nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_${ARCH}.tar.gz"

    # 바이너리 복사
    cp nginx-prometheus-exporter /usr/local/bin/
    chmod +x /usr/local/bin/nginx-prometheus-exporter

    # nginx_exporter 사용자 생성
    if ! id -u nginx_exporter > /dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false nginx_exporter
        log_info "Created nginx_exporter user"
    fi

    # systemd 서비스 파일 생성
    cat > /etc/systemd/system/nginx_exporter.service <<EOF
[Unit]
Description=Nginx Prometheus Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nginx_exporter
Group=nginx_exporter
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter \\
    -nginx.scrape-uri=http://localhost:8080/nginx_status \\
    -web.listen-address=:9113

[Install]
WantedBy=multi-user.target
EOF

    # 서비스 활성화 및 시작
    systemctl daemon-reload
    systemctl enable nginx_exporter
    systemctl start nginx_exporter

    # 정리
    cd /
    rm -rf "$TEMP_DIR"

    log_info "Nginx Exporter installed and started successfully"
    log_info "Nginx Exporter is running on port 9113"
}

################################################################################
# 3. Nginx stub_status 설정 확인 및 안내
################################################################################

configure_nginx_stub_status() {
    log_info "Checking Nginx stub_status configuration..."

    STUB_STATUS_CONF="/etc/nginx/sites-available/stub_status"

    if [ ! -f "$STUB_STATUS_CONF" ]; then
        log_warn "Nginx stub_status configuration not found"
        log_info "Creating stub_status configuration..."

        cat > "$STUB_STATUS_CONF" <<'EOF'
server {
    listen 8080;
    server_name localhost;

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

        # 심볼릭 링크 생성
        if [ ! -L "/etc/nginx/sites-enabled/stub_status" ]; then
            ln -s "$STUB_STATUS_CONF" /etc/nginx/sites-enabled/stub_status
            log_info "Enabled stub_status configuration"
        fi

        # Nginx 설정 테스트
        if nginx -t; then
            systemctl reload nginx
            log_info "Nginx reloaded successfully"
        else
            log_error "Nginx configuration test failed"
            exit 1
        fi
    else
        log_info "Nginx stub_status is already configured"
    fi

    # stub_status 동작 확인
    log_info "Testing stub_status endpoint..."
    if curl -s http://localhost:8080/nginx_status > /dev/null; then
        log_info "Nginx stub_status is working correctly"
    else
        log_warn "Nginx stub_status endpoint is not responding"
        log_warn "Please verify Nginx configuration manually"
    fi
}

################################################################################
# 4. 방화벽 설정 확인
################################################################################

check_firewall() {
    log_info "Checking firewall configuration..."

    # Security Group에서 내부 통신만 허용하도록 안내
    log_info "Ensure Security Group allows:"
    log_info "  - Port 9100 (Node Exporter) from Monitoring Server"
    log_info "  - Port 9113 (Nginx Exporter) from Monitoring Server"
    log_info "  - Port 8080 (stub_status) should be localhost only"
}

################################################################################
# 5. 설치 검증
################################################################################

verify_installation() {
    log_info "Verifying installation..."

    # Node Exporter 상태 확인
    if systemctl is-active --quiet node_exporter; then
        log_info "✓ Node Exporter is running"
        log_info "  Metrics available at: http://localhost:9100/metrics"
    else
        log_error "✗ Node Exporter is not running"
        systemctl status node_exporter --no-pager
    fi

    # Nginx Exporter 상태 확인
    if systemctl is-active --quiet nginx_exporter; then
        log_info "✓ Nginx Exporter is running"
        log_info "  Metrics available at: http://localhost:9113/metrics"
    else
        log_error "✗ Nginx Exporter is not running"
        systemctl status nginx_exporter --no-pager
    fi

    # 메트릭 수집 테스트
    log_info "Testing metrics collection..."

    if curl -s http://localhost:9100/metrics | head -n 5 > /dev/null; then
        log_info "✓ Node Exporter metrics are accessible"
    else
        log_warn "✗ Cannot access Node Exporter metrics"
    fi

    if curl -s http://localhost:9113/metrics | head -n 5 > /dev/null; then
        log_info "✓ Nginx Exporter metrics are accessible"
    else
        log_warn "✗ Cannot access Nginx Exporter metrics"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    log_info "Starting Prometheus Exporters installation..."
    log_info "================================================"

    # 1. Node Exporter 설치
    install_node_exporter

    # 2. Nginx Exporter 설치
    install_nginx_exporter

    # 3. Nginx stub_status 설정
    configure_nginx_stub_status

    # 4. 방화벽 안내
    check_firewall

    # 5. 설치 검증
    verify_installation

    log_info "================================================"
    log_info "Installation completed successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Update Prometheus configuration to scrape this instance"
    log_info "2. Verify Security Group allows monitoring server to access ports 9100 and 9113"
    log_info "3. Check metrics in Grafana dashboards"
    log_info ""
    log_info "Useful commands:"
    log_info "  - Check Node Exporter status: sudo systemctl status node_exporter"
    log_info "  - Check Nginx Exporter status: sudo systemctl status nginx_exporter"
    log_info "  - View Node Exporter logs: sudo journalctl -u node_exporter -f"
    log_info "  - View Nginx Exporter logs: sudo journalctl -u nginx_exporter -f"
    log_info "  - Test metrics: curl http://localhost:9100/metrics"
}

# 스크립트 실행
main
