#!/bin/bash
# 1. 시스템 패키지 업데이트
echo "[1/13] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release awscli jq \
    build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncursesw5-dev libffi-dev liblzma-dev tk-dev \
    poppler-utils

# 2. Java 21 설치
echo "[2/13] Installing Java 21..."
apt-get install -y openjdk-21-jdk
java -version

# 3. pyenv 및 Python 3.10.19 설치
# Ubuntu 22.04에서 pyenv를 사용하여 정확한 Python 버전 관리
echo "[3/13] Installing pyenv and Python 3.10.19..."

# ubuntu 사용자로 pyenv 설치
export HOME=/home/ubuntu
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# pyenv 설치 (ubuntu 사용자로)
sudo -u ubuntu bash -c 'curl https://pyenv.run | bash'

# pyenv 환경변수 설정 (ubuntu 사용자 .bashrc에 추가)
sudo -u ubuntu bash -c 'cat >> /home/ubuntu/.bashrc << "EOF"

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF'

# Python 3.10.19 설치
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pyenv install 3.10.19'

# Python 3.10.19를 전역 기본 버전으로 설정
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pyenv global 3.10.19'

# 시스템 전역에서도 사용 가능하도록 심볼릭 링크 생성
ln -sf /home/ubuntu/.pyenv/versions/3.10.19/bin/python3 /usr/local/bin/python3
ln -sf /home/ubuntu/.pyenv/versions/3.10.19/bin/pip3 /usr/local/bin/pip3
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && python --version'

# 4. ChromaDB 설치
echo "[4/13] Installing ChromaDB..."
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip install --upgrade pip && pip install chromadb'
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip show chromadb'

# 5. Poetry 설치
echo "[5/13] Installing Poetry..."
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && curl -sSL https://install.python-poetry.org | python3 -'

# Poetry PATH 추가
sudo -u ubuntu bash -c 'cat >> /home/ubuntu/.bashrc << "EOF"

# Poetry configuration
export PATH="$HOME/.local/bin:$PATH"
EOF'

# 시스템 전역에서도 사용 가능하도록 심볼릭 링크 생성
ln -sf /home/ubuntu/.local/bin/poetry /usr/local/bin/poetry

sudo -u ubuntu bash -c 'export PATH="/home/ubuntu/.local/bin:$PATH" && poetry --version'

# 6. Node.js 22.21.0 및 pnpm 설치
echo "[6/13] Installing Node.js 22.21.0 and pnpm..."

# NodeSource repository를 사용하여 Node.js 22.x 설치
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Node.js 버전 확인
node -v
npm -v

# pnpm 전역 설치
npm install -g pnpm

# pnpm 버전 확인
pnpm -v

# 7. PostgreSQL 14 설치
# 공식 PostgreSQL 리포지토리를 추가하여 14 버전을 명시적으로 설치
echo "[7/13] Installing PostgreSQL 14..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
apt-get update -y
apt-get install -y postgresql-14 postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "SELECT version();"

# 8. Nginx 설치
# Ubuntu 24.04 저장소의 최신 안정 버전 설치 (1.18.0은 오래된 버전이라 24.04에서 직접 지원이 어려울 수 있음)
echo "[8/13] Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
nginx -v

# 9. Certbot 설치 (Let's Encrypt SSL 인증서용)
echo "[8.5/13] Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

# 10. Nginx 설정 파일 생성
echo "[8.6/13] Configuring Nginx server blocks..."

# 기본 nginx 설정 비활성화
rm -f /etc/nginx/sites-enabled/default

# 상세 로그 포맷 정의
cat > /etc/nginx/conf.d/log_format.conf << 'EOF'
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time" '
                    'host=$host env=${environment}';
EOF

# API (Spring Boot) - ${env_prefix}api.${domain_name}
cat > /etc/nginx/sites-available/be << 'EOF'
server {
    listen 80;
    server_name ${env_prefix}api.${domain_name};

    # 로그 설정 (상세 로그 포맷 사용)
    access_log /var/log/nginx/be_access.log detailed;
    error_log /var/log/nginx/be_error.log warn;

    # 블루그린
    include /etc/nginx/conf.d/service-url.inc;

    # 숨김 파일 접근 금지 (.env, .git 등)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location / {
        proxy_pass $service_url;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Frontend (Next.js) - ${fe_server_names}
cat > /etc/nginx/sites-available/fe << 'EOF'
server {
    listen 80;
    server_name ${fe_server_names};

    # 로그 설정 (상세 로그 포맷 사용)
    access_log /var/log/nginx/fe_access.log detailed;
    error_log /var/log/nginx/fe_error.log warn;

    # 숨김 파일 접근 금지 (.env, .git 등)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# AI (FastAPI) - ${env_prefix}ai.${domain_name}
cat > /etc/nginx/sites-available/ai << 'EOF'
server {
    listen 80;
    server_name ${env_prefix}ai.${domain_name};

    # 로그 설정 (상세 로그 포맷 사용)
    access_log /var/log/nginx/ai_access.log detailed;
    error_log /var/log/nginx/ai_error.log warn;

    # 숨김 파일 접근 금지 (.env, .git 등)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 점검중 HTML 작성
cat > /var/www/html/maintenance.html << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Devths - Maintenance</title>
    <style>
        :root {
            --primary-green: #00ff88; /* 강조될 초록색 */
            --bg-dark: #0a0f12;      /* 깊이감 있는 다크 배경 */
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Pretendard', -apple-system, system-ui, sans-serif;
            background-color: var(--bg-dark);
            display: flex; justify-content: center; align-items: center;
            min-height: 100vh; color: #ececec; overflow: hidden;
        }
        /* 배경에 은은한 그린 그라데이션 효과 추가 */
        body::before {
            content: ''; position: absolute; width: 300px; height: 300px;
            background: var(--primary-green); filter: blur(150px);
            opacity: 0.15; z-index: 0; top: 10%; left: 10%;
        }
        .container {
            position: relative; z-index: 1; text-align: center;
            padding: 3rem; border: 1px solid rgba(0, 255, 136, 0.2);
            border-radius: 24px; background: rgba(255, 255, 255, 0.03);
            backdrop-filter: blur(10px); max-width: 500px;
        }
        .brand {
            font-size: 1.2rem; font-weight: 800; letter-spacing: 2px;
            color: var(--primary-green); margin-bottom: 2rem;
            text-transform: uppercase; display: block;
        }
        .icon {
            font-size: 4rem; margin-bottom: 1.5rem;
            filter: drop-shadow(0 0 15px var(--primary-green));
            animation: float 3s ease-in-out infinite;
        }
        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-15px); }
        }
        h1 {
            font-size: 2rem; margin-bottom: 1rem; font-weight: 700;
            background: linear-gradient(to right, #fff, var(--primary-green));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        p { font-size: 1.1rem; line-height: 1.6; opacity: 0.8; margin-bottom: 2rem; }
        .spinner {
            margin: 0 auto; width: 40px; height: 40px;
            border: 3px solid rgba(0, 255, 136, 0.1);
            border-top-color: var(--primary-green);
            border-radius: 50%; animation: spin 1s cubic-bezier(0.5, 0, 0.5, 1) infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .footer { font-size: 0.85rem; opacity: 0.5; margin-top: 2.5rem; }
    </style>
</head>
<body>
<div class="container">
    <span class="brand">Devths</span>
    <div class="icon">🖥️</div>
    <h1>사이트 점검중</h1>
    <p>더 빠르고 안정적인 <b>Devths</b>를 위해<br>점검 작업을 진행하고 있습니다.</p>
    <div class="spinner"></div>
    <div class="footer">잠시 후 다시 접속해 주세요.</div>
</div>
</body>
</html>
EOF

# 심볼릭 링크 생성 (sites-enabled로 활성화)
echo "[8.7/13] Creating symbolic links..."
ln -sf /etc/nginx/sites-available/be /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/fe /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/ai /etc/nginx/sites-enabled/

# Nginx 설정 테스트 및 재시작
echo "[8.8/13] Testing Nginx configuration..."
nginx -t
systemctl reload nginx

# SSL 인증서 자동 발급 (도메인이 이미 이 서버를 가리키고 있어야 함)
# 주의: 도메인 DNS가 설정되지 않았다면 이 단계는 실패할 수 있습니다.
# 실패해도 나중에 수동으로 실행 가능: certbot --nginx ${certbot_domains}
echo "[8.9/13] Requesting SSL certificates with Certbot..."
sudo certbot --nginx ${certbot_domains} --non-interactive --agree-tos --email ktb_devth@gmail.com --redirect || echo "Certbot failed. You can run it manually later after DNS is configured."
sudo certbot --nginx -d monitoring.devths.com --non-interactive --agree-tos --email ktb_devth@gmail.com --redirect || echo "Certbot failed. You can run it manually later after DNS is configured."

# 점검중 페이지 서버 블록 작성 (SSL 인증서 발급 후)
echo "[8.10/13] Creating maintenance server block..."
cat > /etc/nginx/sites-available/maintenance << 'EOF'
server {
    listen 80;
    listen 443 ssl;
    server_name ${fe_server_names};

    # SSL 설정
    ssl_certificate /etc/letsencrypt/live/${ssl_cert_domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${ssl_cert_domain}/privkey.pem;

    # 로그 설정 (상세 로그 포맷 사용)
    access_log /var/log/nginx/maintenance_access.log detailed;
    error_log /var/log/nginx/maintenance_error.log warn;

    root /var/www/html; # 점검 페이지 HTML이 위치한 경로
    error_page 503 /maintenance.html;

    # 숨김 파일 접근 금지 (.env, .git 등)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location / {
        return 503;
    }

    location = /maintenance.html {
        internal;
    }
}
EOF

cat > /etc/nginx/conf.d/service-url.inc << 'EOF'
set $service_url http://127.0.0.1:8080;
EOF


# -----------------------------------------------------------
# 11. Fail2ban 설치 및 설정 (보안)
# -----------------------------------------------------------
echo "[9/13] Installing and configuring Fail2ban..."
apt-get install -y fail2ban
cd /etc/fail2ban

# 필터링
cat > /etc/fail2ban/filter.d/nginx-forbidden.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD|PROPFIND|CONNECT).*(env|config|php|git|yaml|sql|vendor|jenkins).*".* (404|403|444|405|400|301)
ignoreregex =
EOF

# 디스코드 알림
cat > /etc/fail2ban/action.d/discord-notify.conf << 'EOF'
[Definition]
actionban = curl -H "Content-Type: application/json" -X POST -d '{
    "content": "⚠️  <@&1462613320942223410> **[${server_label}] 보안 위협 감지!**",
    "embeds": [{
      "title": "🚨 실시간 탐지 보고",
      "description": "서버에 비정상적인 접근 시도가 발생했습니다.",
      "color": 15158332,
      "fields": [
        { "name": "🔒 공격자 IP", "value": "`<ip>`", "inline": true },
        { "name": "📂 감시 항목", "value": "`<name>`", "inline": true },
        { "name": "📊 시도 횟수", "value": "**<failures>회**", "inline": true },
        { "name": "🌐 환경", "value": "**${environment}**", "inline": true }
      ],
      "footer": { "text": "Fail2Ban Protection System" }
    }]
  }' "${discord_webhook_url}"

actionunban =
EOF

cp jail.conf jail.local

cat > /etc/fail2ban/jail.local << 'EOF'
[nginx-env-scan]
enabled = true
port = http,https
filter = nginx-forbidden
logpath = /var/log/nginx/*.log
maxretry = 5
findtime = 600
bantime = 200
action = discord-notify
         iptables-multiport[name=nginx-env, port="http,https", protocol=tcp]
EOF

# Fail2ban 시작 및 활성화
systemctl enable fail2ban
systemctl start fail2ban

# -----------------------------------------------------------
# 12. CodeDeploy 에이전트 설치
# -----------------------------------------------------------
echo "[10/13] Installing CodeDeploy Agent..."
# 1. 시스템 업데이트 및 필수 패키지(Ruby) 설치
sudo apt update
sudo apt install ruby-full wget -y

# 2. 설치 파일 다운로드 (서울 리전 기준)
cd /home/ubuntu
wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install

# 3. 설치 권한 부여 및 실행
chmod +x ./install
sudo ./install auto

# CodeDeploy 에이전트 시작 및 활성화
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# -----------------------------------------------------------
# 추가 시스템 설정
# -----------------------------------------------------------

# 13. 타임존 설정 (Asia/Seoul)
echo "[11/13] Setting timezone to Asia/Seoul..."
timedatectl set-timezone Asia/Seoul

# 14. CloudWatch Agent 설치 및 설정
echo "[12/13] Installing CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm ./amazon-cloudwatch-agent.deb

# 기본 메트릭 설정 파일 생성 (메모리, 디스크 사용량)
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "${cloudwatch_namespace}",
    "append_dimensions": {
      "Environment": "${environment}"
    },
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["/"] },
      "jmx": [
        {
          "endpoint": "localhost:9010",
          "jvm": {
            "measurement": [
              "jvm.memory.heap.used",
              "jvm.threads.count",
              "jvm.gc.collections.count"
            ]
          }
        },
        {
          "endpoint": "localhost:9011",
          "jvm": {
            "measurement": [
              "jvm.memory.heap.used",
              "jvm.threads.count",
              "jvm.gc.collections.count"
            ]
          }
        }
      ]
    }
  }
}
EOF

# CloudWatch Agent 실행
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json