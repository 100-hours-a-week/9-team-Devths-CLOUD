#!/bin/bash
# 1. 루트 권한 확보 및 에러 발생 시 즉시 중단
set -e

# 2. 모든 출력을 로그 파일로 기록 (실시간 확인용)
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== NAT Instance User Data 시작 (실행 유저: $(whoami)) ==="

# 3. IP Forwarding 설정 (루트 권한으로 파일 생성)
sudo sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-nat-forwarding.conf'
sudo sysctl -p /etc/sysctl.d/99-nat-forwarding.conf
echo "✓ IP forwarding 활성화 완료"

# 4. iptables 서비스 설치 및 시작
echo "iptables 설치 중..."
sudo dnf install -y iptables-services

# 5. 인터페이스 감지 및 NAT 규칙 적용
PRIMARY_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "감지된 네트워크 인터페이스: $PRIMARY_IF"

sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o $PRIMARY_IF -j MASQUERADE
sudo service iptables save

sudo systemctl enable iptables
sudo systemctl start iptables
echo "✓ iptables NAT 설정 및 서비스 시작 완료"

# 6. SSM Agent 상태 확인 및 강제 시작
if ! rpm -q amazon-ssm-agent > /dev/null; then
    sudo dnf install -y amazon-ssm-agent
fi
sudo systemctl enable amazon-ssm-agent
sudo systemctl restart amazon-ssm-agent
echo "✓ SSM Agent 설정 완료"

# 7. CloudWatch Agent 설치
sudo dnf install -y amazon-cloudwatch-agent
echo "✓ CloudWatch Agent 설치 완료"

echo "=== NAT Instance User Data 완료 ==="