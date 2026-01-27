#!/bin/bash
# 로그를 /var/log/user-data.log에 저장하여 디버깅 용이하게 설정
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting User Data Script: Infra Setup"
echo "Ubuntu 22.04 LTS"
echo "=========================================="

# 1. 시스템 패키지 업데이트
echo "[1/9] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release \
    build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils \
    tk-dev libffi-dev liblzma-dev git

# 2. Java 21 설치
echo "[2/9] Installing Java 21..."
apt-get install -y openjdk-21-jdk
java -version

# 3. pyenv 및 Python 3.10.19 설치
# Ubuntu 22.04에서 pyenv를 사용하여 정확한 Python 버전 관리
echo "[3/9] Installing pyenv and Python 3.10.19..."

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
echo "[4/9] Installing ChromaDB..."
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip install --upgrade pip && pip install chromadb'

echo "ChromaDB installed:"
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip show chromadb'

# 5. Poetry 설치
echo "[5/9] Installing Poetry..."
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

# 6. Node.js 22.21.0 설치 (nvm 사용)
echo "[6/9] Installing Node.js 22.21.0 via nvm..."

# nvm 설치
sudo -u ubuntu bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'

# nvm 환경변수 설정
sudo -u ubuntu bash -c 'cat >> /home/ubuntu/.bashrc << "EOF"

# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF'

# Node.js 22.21.0 설치
sudo -u ubuntu bash -c 'export NVM_DIR="/home/ubuntu/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install 22.21.0 && nvm use 22.21.0 && nvm alias default 22.21.0'

# 시스템 전역에서도 사용 가능하도록 심볼릭 링크 생성
ln -sf /home/ubuntu/.nvm/versions/node/v22.21.0/bin/node /usr/local/bin/node
ln -sf /home/ubuntu/.nvm/versions/node/v22.21.0/bin/npm /usr/local/bin/npm
ln -sf /home/ubuntu/.nvm/versions/node/v22.21.0/bin/npx /usr/local/bin/npx

echo "Node.js version installed:"
sudo -u ubuntu bash -c 'export NVM_DIR="/home/ubuntu/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && node --version && npm --version'

# 7. PostgreSQL 14 설치
# Ubuntu 22.04에서 공식 PostgreSQL 리포지토리를 추가하여 14 버전을 명시적으로 설치
echo "[7/9] Installing PostgreSQL 14..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
apt-get update -y
apt-get install -y postgresql-14 postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "SELECT version();"

# 8. Nginx 설치
# Ubuntu 22.04 저장소의 최신 안정 버전 설치
echo "[8/9] Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
nginx -v

# 9. Certbot 설치 (Let's Encrypt SSL 인증서용)
echo "[9/9] Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

echo "Certbot version installed:"
certbot --version

# Nginx 설정 디렉토리 준비
echo "Setting up Nginx configuration directories..."
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# 기본 Nginx 설정 파일에 sites-enabled 디렉토리 포함 확인
if ! grep -q "include /etc/nginx/sites-enabled/\*;" /etc/nginx/nginx.conf; then
    sed -i '/include \/etc\/nginx\/conf.d\/\*.conf;/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
fi

# www.devths.com 설정 파일 생성 (Next.js - 포트 3000)
cat > /etc/nginx/sites-available/www.devths.com << 'EOF'
server {
    listen 80;
    server_name www.devths.com devths.com;

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

# api.devths.com 설정 파일 생성 (Spring Boot - 포트 8080)
cat > /etc/nginx/sites-available/api.devths.com << 'EOF'
server {
    listen 80;
    server_name api.devths.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

# ai.devths.com 설정 파일 생성 (FastAPI - 포트 8000)
cat > /etc/nginx/sites-available/ai.devths.com << 'EOF'
server {
    listen 80;
    server_name ai.devths.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

# 심볼릭 링크 생성
ln -sf /etc/nginx/sites-available/www.devths.com /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/api.devths.com /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/ai.devths.com /etc/nginx/sites-enabled/

# 기본 Nginx 사이트 비활성화
rm -f /etc/nginx/sites-enabled/default

# Nginx 설정 테스트
nginx -t

# Nginx 재시작
systemctl restart nginx

echo "=========================================="
echo "Nginx Configuration Created:"
echo "  - www.devths.com (Next.js -> localhost:3000)"
echo "  - api.devths.com (Spring Boot -> localhost:8080)"
echo "  - ai.devths.com (FastAPI -> localhost:8000)"
echo ""
echo "SSL Certificate Setup:"
echo "Run these commands after DNS is properly configured:"
echo "  sudo certbot --nginx -d www.devths.com -d devths.com"
echo "  sudo certbot --nginx -d api.devths.com"
echo "  sudo certbot --nginx -d ai.devths.com"
echo "=========================================="

echo "=========================================="
echo "User Data Script Completed Successfully!"
echo "Installed:"
echo "  - Java 21 JRE"
echo "  - Python 3.10.19 (via pyenv)"
echo "  - ChromaDB"
echo "  - Poetry"
echo "  - Node.js 22.21.0 (via nvm)"
echo "  - PostgreSQL 14"
echo "  - Nginx (with domain configurations)"
echo "  - Certbot"
echo "=========================================="