#!/bin/bash
# 1. 시스템 패키지 업데이트
echo "[1/9] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common curl wget gnupg2 lsb-release awscli jq \
    ca-certificates apt-transport-https

# 2. Docker 설치
echo "[2/9] Installing Docker Engine..."
# Docker 공식 GPG 키 추가
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker 리포지토리 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 패키지 설치
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작 및 활성화
systemctl enable docker
systemctl start docker

# ubuntu 사용자를 docker 그룹에 추가
usermod -aG docker ubuntu

# Docker 버전 확인
docker --version
docker compose version

# Docker 재시작하여 설정 적용
systemctl restart docker

# -----------------------------------------------------------
# 8. CodeDeploy 에이전트 설치
# -----------------------------------------------------------
echo "[4/9] Installing CodeDeploy Agent..."
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
# 9. 추가 시스템 설정
# -----------------------------------------------------------
echo "SSM Agent 설치 시작 (APT)..."

cd /tmp
# -q 옵션으로 로그 간소화, -O로 파일명 명시
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb -O amazon-ssm-agent.deb

# dpkg 설치 시 의존성 문제가 발생하면 fix해주기 위해 -f install 추가 가능
sudo dpkg -i amazon-ssm-agent.deb
sudo apt-get install -f -y  # 혹시 모를 의존성 깨짐 방지

sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

rm amazon-ssm-agent.deb

echo "✓ SSM Agent APT 설치 완료"
sudo systemctl status amazon-ssm-agent --no-pager

# 타임존 설정 (Asia/Seoul)
echo "[9/9] Setting timezone to Asia/Seoul..."
timedatectl set-timezone Asia/Seoul