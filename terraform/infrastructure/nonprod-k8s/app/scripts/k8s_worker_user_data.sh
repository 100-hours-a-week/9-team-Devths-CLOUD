#!/bin/bash
# 에러 발생 시 즉시 중단, 정의되지 않은 변수 사용 시 에러, 파이프 에러 유지 설정
set -euxo pipefail

# 로그 기록 설정: 콘솔 출력과 동시에 /var/log/k8s-worker-bootstrap.log 파일에 저장
exec > >(tee /var/log/k8s-worker-bootstrap.log | logger -t user-data -s 2>/dev/console) 2>&1

# 테라폼으로부터 전달받은 변수 설정
NODE_NAME="${node_name}"
KUBERNETES_VERSION="${kubernetes_version}"
CLUSTER_NAME="${cluster_name}"
TIMEZONE="${timezone}"
JOIN_COMMAND_SSM_PATH="${join_command_ssm_path}"

# 호스트네임 설정 및 타임존 설정
hostnamectl set-hostname "$${NODE_NAME}"
timedatectl set-timezone "$${TIMEZONE}"

# 시스템 패키지 업데이트 및 기본 도구 설치
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https \
  ca-certificates \
  conntrack \
  containerd \
  curl \
  ebtables \
  ethtool \
  gnupg \
  jq \
  socat \
  wget \
  awscli

# 스왑 메모리 비활성화 (쿠버네티스 권장 사항)
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# 컨테이너 런타임 및 네트워크용 커널 모듈 로드 설정
cat <<'EOT' >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOT

modprobe overlay
modprobe br_netfilter

# 쿠버네티스 네트워킹을 위한 커널 파라미터(sysctl) 설정
cat <<'EOT' >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOT

# 설정된 커널 파라미터 적용
sysctl --system

# Containerd 설정: Systemd를 Cgroup 관리자로 사용하도록 설정
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable containerd
systemctl restart containerd

# AWS SSM Agent 설치 (AWS 콘솔에서 원격 접속을 위해 필요)
cd /tmp
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb -O amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb || apt-get install -f -y
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent
rm -f amazon-ssm-agent.deb

# 쿠버네티스 패키지 저장소(apt) 키 등록 및 소스 리스트 추가
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$${KUBERNETES_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat <<EOT >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$${KUBERNETES_VERSION}/deb/ /
EOT

# kubelet, kubeadm, kubectl 설치 및 버전 고정(자동 업데이트 방지)
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# EC2 IMDSv2를 통해 현재 인스턴스의 로컬 IP 정보 가져오기
IMDS_TOKEN=$(curl -fsSL -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
NODE_IP=$(curl -fsSL -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" "http://169.254.169.254/latest/meta-data/local-ipv4")
INSTANCE_ID=$(curl -fsSL -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" "http://169.254.169.254/latest/meta-data/instance-id")
AWS_REGION=$(curl -fsSL -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" "http://169.254.169.254/latest/meta-data/placement/region")

# kubelet 실행 시 사용할 노드 IP 설정
cat <<EOT >/etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=$${NODE_IP}
EOT

systemctl enable kubelet
systemctl restart kubelet || true

# 워커 노드 조인 스크립트 생성
cat <<'EOT' >/usr/local/bin/k8s-worker-join.sh
#!/bin/bash
set -euxo pipefail

# IP 재확인
IMDS_TOKEN=$(curl -fsSL -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION=$(curl -fsSL -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" "http://169.254.169.254/latest/meta-data/placement/region")

# SSM Parameter Store에서 join 명령어 가져오기
JOIN_COMMAND=$(aws ssm get-parameter \
  --name "${join_command_ssm_path}" \
  --region "$${AWS_REGION}" \
  --query "Parameter.Value" \
  --output text 2>/dev/null || echo "")

if [ -z "$${JOIN_COMMAND}" ]; then
  echo "조인 명령을 찾을 수 없습니다. SSM Parameter Store에 저장되었는지 확인하세요."
  echo "경로: ${join_command_ssm_path}"
  exit 1
fi

# kubeadm join 실행
eval "$${JOIN_COMMAND}"

echo "워커 노드가 클러스터에 조인되었습니다."
EOT

chmod +x /usr/local/bin/k8s-worker-join.sh

# 서버 접속 시 나타나는 환영 메시지(MOTD) 설정
cat <<EOT >/etc/motd
쿠버네티스 워커 노드 부트스트랩이 완료되었습니다.

다음 단계를 수행하세요:
1. SSM으로 서버에 접속합니다.
2. 마스터 노드에서 'kubeadm token create --print-join-command'를 실행합니다.
3. 생성된 join 명령을 SSM Parameter Store에 저장합니다:
   경로: ${join_command_ssm_path}
4. 이 워커 노드에서 실행: sudo /usr/local/bin/k8s-worker-join.sh

또는 자동 조인이 설정되어 있다면, 이미 클러스터에 조인되었을 수 있습니다.
'kubectl get nodes'로 확인하세요.
EOT

echo "워커 노드 부트스트랩 완료"
