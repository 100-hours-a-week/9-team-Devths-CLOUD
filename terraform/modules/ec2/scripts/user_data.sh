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
# 7. Fail2ban 설치 및 설정 (보안)
# -----------------------------------------------------------
echo "[3/9] Installing and configuring Fail2ban..."
apt-get install -y fail2ban
cd /etc/fail2ban

# 필터링
cat > /etc/fail2ban/filter.d/nginx-forbidden.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD|PROPFIND|CONNECT).*(env|config|php|git|yaml|sql|vendor|jenkins).*".* (404|403|444|405|400|301)
ignoreregex =
EOF

# 공격 당했을 때만 알림
cat > /etc/fail2ban/filter.d/nginx-attack.conf << 'EOF'
[Definition]
# 200(성공) 코드가 떴을 때만 탐지 (실제 침투 성공 의심)
failregex = ^<HOST> -.*"(GET|POST|HEAD|PROPFIND|CONNECT).*(env|config|php|git|yaml|sql|vendor|jenkins).*".* (200)
ignoreregex =
EOF
EOF


# 디스코드 알림
cat > /etc/fail2ban/action.d/discord-notify.conf << 'EOF'
[Definition]
actionban = curl -H "Content-Type: application/json" -X POST -d '{
    "content": "⚠️  <@&1462613320942223410> **[${server_label}] 보안 위협 감지!**",
    "embeds": [{
      "title": "🚨 실제 침투 성공 의심 보고",
      "description": "공격자가 민감한 경로 접근에 성공(200/30x)한 것으로 보입니다.",
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
# 1. 조용한 차단 (알림 X)
[nginx-env-scan]
enabled = true
port = http,https
filter = nginx-forbidden
logpath = /var/log/nginx/*.log
maxretry = 3
findtime = 600
bantime = 3600
action = iptables-multiport[name=nginx-scan, port="http,https", protocol=tcp]

# 2. 긴급 상황 (알림 O)
[nginx-env-attack]
enabled = true
port = http,https
filter = nginx-attack
logpath = /var/log/nginx/*.log
maxretry = 1
findtime = 600
bantime = 86400
action = discord-notify
         iptables-multiport[name=nginx-attack, port="http,https", protocol=tcp]
EOF

# Fail2ban 시작 및 활성화
systemctl enable fail2ban
systemctl start fail2ban

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
# SSM Agent 설치 및 시작 (Ubuntu 22.04 전용)
echo "SSM Agent 설정 시작..."

# 1. snap을 통해 amazon-ssm-agent 설치 여부 확인 및 설치
if ! snap list amazon-ssm-agent > /dev/null 2>&1; then
    echo "SSM Agent 설치 중..."
    sudo snap install amazon-ssm-agent --classic
else
    echo "SSM Agent가 이미 설치되어 있습니다."
fi

# 2. 서비스 시작 및 활성화
echo "SSM Agent 서비스 시작 중..."
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent

# 3. 상태 확인
echo "------------------------------------------"
snap list amazon-ssm-agent
echo "✓ SSM Agent 설정 완료"
echo "------------------------------------------"

# 타임존 설정 (Asia/Seoul)
echo "[9/9] Setting timezone to Asia/Seoul..."
timedatectl set-timezone Asia/Seoul