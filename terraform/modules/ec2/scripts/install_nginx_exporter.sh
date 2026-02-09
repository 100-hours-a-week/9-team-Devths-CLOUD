#!/bin/bash
# Nginx Exporter 설치 스크립트
# Usage: sudo bash install_nginx_exporter.sh

set -e

# 변수 설정
NGINX_EXPORTER_VERSION="1.3.0"
NGINX_EXPORTER_USER="nginx_exporter"

echo "[1/6] Enabling Nginx stub_status..."
# Nginx stub_status 활성화 (메트릭 수집용)
sudo tee /etc/nginx/conf.d/stub_status.conf > /dev/null <<'EOF'
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    location /stub_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

# Nginx 설정 테스트 및 재시작
sudo nginx -t
sudo systemctl reload nginx

echo "[2/6] Downloading Nginx Exporter v${NGINX_EXPORTER_VERSION}..."
cd /tmp
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz

echo "[3/6] Extracting Nginx Exporter..."
tar xvfz nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz

echo "[4/6] Installing Nginx Exporter..."
sudo mv nginx-prometheus-exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/nginx-prometheus-exporter

# 정리
rm -rf nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz

echo "[5/6] Creating systemd service..."
# Nginx Exporter 사용자 생성 (시스템 사용자, 로그인 불가)
sudo useradd --no-create-home --shell /bin/false ${NGINX_EXPORTER_USER} || echo "User already exists"

# systemd 서비스 파일 생성
sudo tee /etc/systemd/system/nginx_exporter.service > /dev/null <<EOF
[Unit]
Description=Nginx Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${NGINX_EXPORTER_USER}
Group=${NGINX_EXPORTER_USER}
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://127.0.0.1:8080/stub_status

[Install]
WantedBy=multi-user.target
EOF

echo "[6/6] Starting Nginx Exporter service..."
sudo systemctl daemon-reload
sudo systemctl enable nginx_exporter
sudo systemctl start nginx_exporter

# 상태 확인
echo ""
echo "=========================================="
echo "Nginx Exporter 설치 완료!"
echo "=========================================="
echo ""
sudo systemctl status nginx_exporter --no-pager
echo ""
echo "메트릭 확인: curl http://localhost:9113/metrics"
echo ""
