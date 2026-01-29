#!/bin/bash
# 로그를 /var/log/user-data.log에 저장하여 디버깅 용이하게 설정
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting User Data Script: Infra Setup"
echo "=========================================="

# 1. 시스템 패키지 업데이트
echo "[1/12] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release awscli jq \
    build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncursesw5-dev libffi-dev liblzma-dev tk-dev

# 2. Java 21 설치
echo "[2/12] Installing Java 21..."
apt-get install -y openjdk-21-jdk
java -version

# 3. pyenv 및 Python 3.10.19 설치
# Ubuntu 22.04에서 pyenv를 사용하여 정확한 Python 버전 관리
echo "[3/12] Installing pyenv and Python 3.10.19..."

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

echo "Python version installed:"
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && python --version'

# 4. ChromaDB 설치
echo "[4/12] Installing ChromaDB..."
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip install --upgrade pip && pip install chromadb'

echo "ChromaDB installed:"
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip show chromadb'

# 5. Poetry 설치
echo "[5/12] Installing Poetry..."
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && curl -sSL https://install.python-poetry.org | python3 -'

# Poetry PATH 추가
sudo -u ubuntu bash -c 'cat >> /home/ubuntu/.bashrc << "EOF"

# Poetry configuration
export PATH="$HOME/.local/bin:$PATH"
EOF'

# 시스템 전역에서도 사용 가능하도록 심볼릭 링크 생성
ln -sf /home/ubuntu/.local/bin/poetry /usr/local/bin/poetry

echo "Poetry version installed:"
sudo -u ubuntu bash -c 'export PATH="/home/ubuntu/.local/bin:$PATH" && poetry --version'

# 6. Node.js 22.21.0 및 pnpm 설치
echo "[6/12] Installing Node.js 22.21.0 and pnpm..."

# NodeSource repository를 사용하여 Node.js 22.x 설치
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Node.js 버전 확인
echo "Node.js version installed:"
node -v
npm -v

# pnpm 전역 설치
npm install -g pnpm

# pnpm 버전 확인
echo "pnpm version installed:"
pnpm -v

# 7. PostgreSQL 14 설치
# 공식 PostgreSQL 리포지토리를 추가하여 14 버전을 명시적으로 설치
echo "[7/12] Installing PostgreSQL 14..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
apt-get update -y
apt-get install -y postgresql-14 postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "SELECT version();"

# 8. Nginx 설치
# Ubuntu 24.04 저장소의 최신 안정 버전 설치 (1.18.0은 오래된 버전이라 24.04에서 직접 지원이 어려울 수 있음)
echo "[8/12] Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
nginx -v

# 9. Certbot 설치 (Let's Encrypt SSL 인증서용)
echo "[8.5/12] Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

# 10. Nginx 설정 파일 생성
echo "[8.6/12] Configuring Nginx server blocks..."

# 기본 nginx 설정 비활성화
rm -f /etc/nginx/sites-enabled/default

# API (Spring Boot) - api.devths.com
cat > /etc/nginx/sites-available/be << 'EOF'
server {
    listen 80;
    server_name api.devths.com;

    # 숨김 파일 접근 금지 (.env, .git 등)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location / {
        proxy_pass http://localhost:8080;
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

# Frontend (Next.js) - www.devths.com
cat > /etc/nginx/sites-available/fe << 'EOF'
server {
    listen 80;
    server_name www.devths.com devths.com;

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

# AI (FastAPI) - ai.devths.com
cat > /etc/nginx/sites-available/ai << 'EOF'
server {
    listen 80;
    server_name ai.devths.com;

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
    <title>Devths - 배포 중</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: #fff;
        }

        .container {
            text-align: center;
            padding: 2rem;
            max-width: 600px;
        }

        .icon {
            font-size: 5rem;
            margin-bottom: 1rem;
            animation: pulse 2s ease-in-out infinite;
        }

        @keyframes pulse {
            0%, 100% {
                transform: scale(1);
            }
            50% {
                transform: scale(1.1);
            }
        }

        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            font-weight: 700;
        }

        p {
            font-size: 1.2rem;
            margin-bottom: 0.5rem;
            opacity: 0.9;
        }

        .subtitle {
            font-size: 1rem;
            opacity: 0.7;
            margin-top: 2rem;
        }

        .spinner {
            margin: 2rem auto;
            width: 50px;
            height: 50px;
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top-color: #fff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            to {
                transform: rotate(360deg);
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🚀</div>
        <h1>배포 중입니다</h1>
        <p>더 나은 서비스를 위해 업데이트를 진행하고 있습니다.</p>
        <div class="spinner"></div>
        <p class="subtitle">잠시만 기다려 주세요. 곧 정상적으로 서비스됩니다.</p>
    </div>
</body>
</html>
EOF

# 심볼릭 링크 생성 (sites-enabled로 활성화)
echo "[8.7/12] Creating symbolic links..."
ln -sf /etc/nginx/sites-available/be /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/fe /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/ai /etc/nginx/sites-enabled/

# Nginx 설정 테스트 및 재시작
echo "[8.8/12] Testing Nginx configuration..."
nginx -t
systemctl reload nginx

# SSL 인증서 자동 발급 (도메인이 이미 이 서버를 가리키고 있어야 함)
# 주의: 도메인 DNS가 설정되지 않았다면 이 단계는 실패할 수 있습니다.
# 실패해도 나중에 수동으로 실행 가능: certbot --nginx -d api.devths.com -d www.devths.com -d devths.com -d ai.devths.com
echo "[8.9/12] Requesting SSL certificates with Certbot..."
sudo certbot --nginx -d devths.com -d www.devths.com -d api.devths.com -d ai.devths.com --non-interactive --agree-tos --email ktb_devth@gmail.com --redirect || echo "Certbot failed. You can run it manually later after DNS is configured."

# 점검중 페이지 서버 블록 작성 (SSL 인증서 발급 후)
echo "[8.10/12] Creating maintenance server block..."
cat > /etc/nginx/sites-available/maintenance << 'EOF'
server {
    listen 80;
    listen 443 ssl;
    server_name www.devths.com;

    # SSL 설정
    ssl_certificate /etc/letsencrypt/live/www.devths.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.devths.com/privkey.pem;

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
# 11. CodeDeploy 에이전트 설치
# -----------------------------------------------------------
echo "[9/12] Installing CodeDeploy Agent..."
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

# 12. 타임존 설정 (Asia/Seoul)
echo "[10/12] Setting timezone to Asia/Seoul..."
timedatectl set-timezone Asia/Seoul

# 13. 스왑 메모리 설정 (2GB)
echo "[11/12] Configuring 2GB Swap memory..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "Swap created successfully."
else
    echo "Swap file already exists."
fi

# 14. CloudWatch Agent 설치 및 설정
echo "[12/12] Installing CloudWatch Agent..."
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
    "append_dimensions": {
      "InstanceId": "\${aws:InstanceId}",
      "ImageId": "\${aws:ImageId}",
      "InstanceType": "\${aws:InstanceType}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# CloudWatch Agent 실행
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

echo "=========================================="
echo "User Data Script Completed Successfully!"
echo "=========================================="