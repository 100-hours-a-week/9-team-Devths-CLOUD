#!/bin/bash
# 로그를 /var/log/user-data.log에 저장하여 디버깅 용이하게 설정
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting User Data Script: Infra Setup"
echo "Ubuntu 22.04 LTS"
echo "=========================================="

# 1. 시스템 패키지 업데이트
echo "[1/6] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release \
    build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils \
    tk-dev libffi-dev liblzma-dev git

# 2. Java 21 설치
echo "[2/6] Installing Java 21..."
apt-get install -y openjdk-21-jdk
java -version

# 3. pyenv 및 Python 3.10.19 설치
# Ubuntu 22.04에서 pyenv를 사용하여 정확한 Python 버전 관리
echo "[3/6] Installing pyenv and Python 3.10.19..."

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
echo "[4/6] Installing ChromaDB..."
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip install --upgrade pip && pip install chromadb'

echo "ChromaDB installed:"
sudo -u ubuntu bash -c 'export PYENV_ROOT="/home/ubuntu/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pip show chromadb'

# 5. PostgreSQL 14 설치
# Ubuntu 22.04에서 공식 PostgreSQL 리포지토리를 추가하여 14 버전을 명시적으로 설치
echo "[5/6] Installing PostgreSQL 14..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
apt-get update -y
apt-get install -y postgresql-14 postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "SELECT version();"

# 6. Nginx 설치
# Ubuntu 22.04 저장소의 최신 안정 버전 설치
echo "[6/6] Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
nginx -v

echo "=========================================="
echo "User Data Script Completed Successfully!"
echo "Installed:"
echo "  - Java 21"
echo "  - Python 3.10.19 (via pyenv)"
echo "  - ChromaDB"
echo "  - PostgreSQL 14"
echo "  - Nginx"
echo "=========================================="