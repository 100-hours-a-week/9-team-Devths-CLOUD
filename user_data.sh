#!/bin/bash
# 로그를 /var/log/user-data.log에 저장하여 디버깅 용이하게 설정
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting User Data Script: Infra Setup"
echo "=========================================="

# 1. 시스템 패키지 업데이트
echo "[1/9] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release awscli jq

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

# 4. PostgreSQL 14 설치
# 공식 PostgreSQL 리포지토리를 추가하여 14 버전을 명시적으로 설치
echo "[4/9] Installing PostgreSQL 14..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
apt-get update -y
apt-get install -y postgresql-14 postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "SELECT version();"

# 5. Nginx 설치
# Ubuntu 24.04 저장소의 최신 안정 버전 설치 (1.18.0은 오래된 버전이라 24.04에서 직접 지원이 어려울 수 있음)
echo "[5/9] Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
nginx -v

# -----------------------------------------------------------
# 6. CodeDeploy 에이전트 설치
# -----------------------------------------------------------
echo "[6/9] Installing CodeDeploy Agent..."
cd /home/ubuntu
wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
chmod +x ./install
./install auto

# CodeDeploy 에이전트 시작 및 활성화
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# -----------------------------------------------------------
# 추가 시스템 설정
# -----------------------------------------------------------

# 7. 타임존 설정 (Asia/Seoul)
echo "[7/9] Setting timezone to Asia/Seoul..."
timedatectl set-timezone Asia/Seoul

# 8. 스왑 메모리 설정 (2GB)
echo "[8/9] Configuring 2GB Swap memory..."
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

# 9. CloudWatch Agent 설치 및 설정
echo "[9/9] Installing CloudWatch Agent..."
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