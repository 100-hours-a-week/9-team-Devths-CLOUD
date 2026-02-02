#!/bin/bash
set -e

LOGROTATE_CONF="/etc/logrotate.d/devths-app"

echo "[Logrotate Setup] Creating configuration at $LOGROTATE_CONF..."

# Logrotate 설정 파일 생성
cat <<EOF > $LOGROTATE_CONF
/home/ubuntu/be/logs/*.log
/home/ubuntu/ai/logs/*.log
/home/ubuntu/fe/logs/*.log
{
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    dateext
    create 0644 ubuntu ubuntu
}
EOF

# 권한 설정
chmod 644 $LOGROTATE_CONF
chown root:root $LOGROTATE_CONF

echo "[Logrotate Setup] Configuration created successfully!"

# 테스트 실행 (Dry run)
echo "[Logrotate Setup] Verifying configuration..."
logrotate -d $LOGROTATE_CONF
