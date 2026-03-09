#!/bin/bash
# Node Exporter 설치 스크립트
# Usage: sudo bash install_node_exporter.sh

set -e

# 변수 설정
NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_USER="node_exporter"

echo "[1/5] Downloading Node Exporter v${NODE_EXPORTER_VERSION}..."
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

echo "[2/5] Extracting Node Exporter..."
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

echo "[3/5] Installing Node Exporter..."
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter

# 정리
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

echo "[4/5] Creating systemd service..."
# Node Exporter 사용자 생성 (시스템 사용자, 로그인 불가)
sudo useradd --no-create-home --shell /bin/false ${NODE_EXPORTER_USER} || echo "User already exists"

# systemd 서비스 파일 생성
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "[5/5] Starting Node Exporter service..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# 상태 확인
echo ""
echo "=========================================="
echo "Node Exporter 설치 완료!"
echo "=========================================="
echo ""
sudo systemctl status node_exporter --no-pager
echo ""
echo "메트릭 확인: curl http://localhost:9100/metrics"
echo ""
