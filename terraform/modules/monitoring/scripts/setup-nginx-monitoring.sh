#!/bin/bash

################################################################################
# 모니터링 서버 Nginx 설정 스크립트
# 대상: 모니터링 EC2 인스턴스 (Non-Prod, Prod)
# 설정 항목: Grafana 리버스 프록시, SSL 인증서
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

# 환경 파라미터
ENVIRONMENT=""
DOMAIN=""

# 사용법 출력
usage() {
    echo "Usage: $0 -e <environment> -d <domain>"
    echo ""
    echo "Options:"
    echo "  -e    Environment (nonprod or prod)"
    echo "  -d    Domain name (e.g., monitoring.dev.devths.com or monitoring.devths.com)"
    echo ""
    echo "Example:"
    echo "  $0 -e nonprod -d monitoring.dev.devths.com"
    echo "  $0 -e prod -d monitoring.devths.com"
    exit 1
}

# 파라미터 파싱
while getopts "e:d:h" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        d)
            DOMAIN="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            log_error "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done

# 필수 파라미터 확인
if [ -z "$ENVIRONMENT" ] || [ -z "$DOMAIN" ]; then
    log_error "Missing required parameters"
    usage
fi

# 환경 검증
if [[ "$ENVIRONMENT" != "nonprod" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Environment must be 'nonprod' or 'prod'"
    exit 1
fi

log_info "Setting up Nginx for $ENVIRONMENT environment"
log_info "Domain: $DOMAIN"

################################################################################
# 1. Nginx 설치
################################################################################

install_nginx() {
    log_info "Installing Nginx..."

    if command -v nginx &> /dev/null; then
        log_info "Nginx is already installed"
        nginx -v
    else
        apt-get update
        apt-get install -y nginx
        log_info "Nginx installed successfully"
    fi
}

################################################################################
# 2. Certbot 설치
################################################################################

install_certbot() {
    log_info "Installing Certbot..."

    if command -v certbot &> /dev/null; then
        log_info "Certbot is already installed"
        certbot --version
    else
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
        log_info "Certbot installed successfully"
    fi
}

################################################################################
# 3. Nginx 설정 파일 생성
################################################################################

create_nginx_config() {
    log_info "Creating Nginx configuration..."

    CONFIG_NAME="grafana-${ENVIRONMENT}"
    CONFIG_PATH="/etc/nginx/sites-available/${CONFIG_NAME}"

    # Grafana upstream 설정
    cat > "$CONFIG_PATH" <<EOF
upstream grafana_${ENVIRONMENT} {
    server 127.0.0.1:3001;
    keepalive 32;
}

server {
    listen 80;
    server_name ${DOMAIN};

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # HTTP to HTTPS redirect (SSL 인증서 발급 후 활성화)
    # return 301 https://\$server_name\$request_uri;

    # 임시 프록시 (SSL 인증서 발급 전)
    location / {
        proxy_pass http://grafana_${ENVIRONMENT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # 심볼릭 링크 생성
    if [ ! -L "/etc/nginx/sites-enabled/${CONFIG_NAME}" ]; then
        ln -s "$CONFIG_PATH" "/etc/nginx/sites-enabled/${CONFIG_NAME}"
        log_info "Enabled Nginx configuration"
    fi

    # Nginx 설정 테스트
    if nginx -t; then
        systemctl reload nginx
        log_info "Nginx configuration applied successfully"
    else
        log_error "Nginx configuration test failed"
        exit 1
    fi
}

################################################################################
# 4. SSL 인증서 발급
################################################################################

setup_ssl() {
    log_info "Setting up SSL certificate..."

    # DNS가 설정되어 있는지 확인
    log_warn "Please ensure DNS record for $DOMAIN points to this server's IP"
    read -p "Is DNS configured? (yes/no): " dns_ready

    if [[ "$dns_ready" != "yes" ]]; then
        log_warn "Skipping SSL setup. Run 'sudo certbot --nginx -d $DOMAIN' manually after DNS is configured"
        return
    fi

    # Let's Encrypt 인증서 발급
    log_info "Obtaining SSL certificate from Let's Encrypt..."

    if certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@devths.com; then
        log_info "SSL certificate obtained successfully"

        # HTTPS 설정 업데이트
        update_nginx_ssl_config
    else
        log_error "Failed to obtain SSL certificate"
        log_warn "You can try manually: sudo certbot --nginx -d $DOMAIN"
        return 1
    fi
}

################################################################################
# 5. HTTPS 설정 업데이트
################################################################################

update_nginx_ssl_config() {
    log_info "Updating Nginx configuration for HTTPS..."

    CONFIG_NAME="grafana-${ENVIRONMENT}"
    CONFIG_PATH="/etc/nginx/sites-available/${CONFIG_NAME}"

    # SSL 설정이 포함된 전체 설정 파일 생성
    cat > "$CONFIG_PATH" <<EOF
upstream grafana_${ENVIRONMENT} {
    server 127.0.0.1:3001;
    keepalive 32;
}

server {
    listen 80;
    server_name ${DOMAIN};

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # HTTP to HTTPS redirect
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    # SSL 인증서
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # SSL 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/grafana-${ENVIRONMENT}-access.log;
    error_log /var/log/nginx/grafana-${ENVIRONMENT}-error.log;

    # Client body size
    client_max_body_size 50M;

    # Grafana 프록시
    location / {
        proxy_pass http://grafana_${ENVIRONMENT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_read_timeout 90;
        proxy_buffering off;
    }

    # Grafana API WebSocket
    location /api/live/ {
        proxy_pass http://grafana_${ENVIRONMENT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Nginx 설정 테스트
    if nginx -t; then
        systemctl reload nginx
        log_info "HTTPS configuration applied successfully"
    else
        log_error "Nginx configuration test failed"
        exit 1
    fi
}

################################################################################
# 6. 자동 갱신 설정
################################################################################

setup_auto_renewal() {
    log_info "Setting up SSL certificate auto-renewal..."

    # Certbot 자동 갱신은 systemd timer로 자동 설정됨
    systemctl list-timers | grep certbot

    log_info "SSL certificate will be automatically renewed"
    log_info "Check renewal with: sudo certbot renew --dry-run"
}

################################################################################
# 7. 방화벽 설정 확인
################################################################################

check_firewall() {
    log_info "Checking firewall configuration..."

    log_info "Ensure Security Group allows:"
    log_info "  - Port 80 (HTTP) from 0.0.0.0/0"
    log_info "  - Port 443 (HTTPS) from 0.0.0.0/0"
    log_info "  - Port 3001 should only be accessible from localhost"
}

################################################################################
# Main Execution
################################################################################

main() {
    log_info "Starting Nginx setup for monitoring server..."
    log_info "================================================"

    # 1. Nginx 설치
    install_nginx

    # 2. Certbot 설치
    install_certbot

    # 3. Nginx 설정 생성
    create_nginx_config

    # 4. SSL 인증서 설정
    setup_ssl

    # 5. 자동 갱신 설정
    setup_auto_renewal

    # 6. 방화벽 안내
    check_firewall

    log_info "================================================"
    log_info "Nginx setup completed!"
    log_info ""
    log_info "Access Grafana at: https://$DOMAIN"
    log_info ""
    log_info "Next steps:"
    log_info "1. Configure Route53 A record for $DOMAIN"
    log_info "2. Update Security Group to allow ports 80 and 443"
    log_info "3. Start Docker containers: cd /path/to/monitoring/$ENVIRONMENT && docker-compose up -d"
    log_info "4. Access Grafana and complete initial setup"
    log_info ""
    log_info "Useful commands:"
    log_info "  - Check Nginx status: sudo systemctl status nginx"
    log_info "  - Test Nginx config: sudo nginx -t"
    log_info "  - Reload Nginx: sudo systemctl reload nginx"
    log_info "  - Check SSL certificate: sudo certbot certificates"
    log_info "  - Renew certificate manually: sudo certbot renew"
}

# 스크립트 실행
main
