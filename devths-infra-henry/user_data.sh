#!/bin/bash
# 로그를 /var/log/user-data.log에 저장하여 디버깅 용이하게 설정
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting User Data Script: Infra Setup"
echo "=========================================="

# 1. 시스템 패키지 업데이트
echo "[1/5] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release

# 2. Java 21 설치
echo "[2/5] Installing Java 21..."
apt-get install -y openjdk-21-jdk
java -version

# 3. Python 3.10 설치
# Ubuntu 24.04의 기본 파이썬은 3.12이므로, 3.10 설치를 위해 PPA 추가
echo "[3/5] Installing Python 3.10..."
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update -y
apt-get install -y python3.10 python3.10-venv python3.10-dev
python3.10 --version

# 4. PostgreSQL 14 설치
# 공식 PostgreSQL 리포지토리를 추가하여 14 버전을 명시적으로 설치
echo "[4/5] Installing PostgreSQL 14..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
apt-get update -y
apt-get install -y postgresql-14 postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "SELECT version();"

# 5. Nginx 설치
# Ubuntu 24.04 저장소의 최신 안정 버전 설치 (1.18.0은 오래된 버전이라 24.04에서 직접 지원이 어려울 수 있음)
echo "[5/5] Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
nginx -v

echo "=========================================="
echo "User Data Script Completed Successfully!"
echo "=========================================="
