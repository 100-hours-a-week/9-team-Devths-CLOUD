# Non-Prod 모니터링 환경 Terraform 설정

Non-Prod VPC에 Prometheus + Grafana 모니터링 서버를 배포합니다. Dev와 Staging 환경을 통합 모니터링합니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Non-Prod VPC                             │
│                                                              │
│  ┌────────────────────────────────────┐                    │
│  │  모니터링 EC2                      │                    │
│  │  - Docker + Docker Compose         │                    │
│  │  - Prometheus (port 9090)          │                    │
│  │  - Grafana (port 3001)             │                    │
│  │  - Nginx (ports 80/443)            │                    │
│  │  - EIP 할당                        │                    │
│  └────────────────────────────────────┘                    │
│              ↓ scrapes                                      │
│  ┌─────────────────────┐   ┌─────────────────────┐         │
│  │  Dev EC2            │   │  Staging EC2        │         │
│  │  - node_exporter    │   │  - node_exporter    │         │
│  │  - nginx_exporter   │   │  - nginx_exporter   │         │
│  └─────────────────────┘   └─────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 사전 요구사항

다음 리소스가 먼저 생성되어 있어야 합니다:

1. **Non-Prod VPC** (`terraform/infrastructure/common/vpc-nonprod-v2`)
2. **Dev 환경** (`terraform/infrastructure/dev`)
3. **Staging 환경** (`terraform/infrastructure/staging`)
4. **Route53 Hosted Zone** (`terraform/infrastructure/common/route53`)
5. **IAM 역할** (Dev 환경의 EC2 IAM 역할 재사용)

## 배포 순서

### 1. 변수 파일 생성

```bash
cd terraform/infrastructure/nonprod-monitoring
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

필수 변수 설정:
```hcl
key_name               = "your-ec2-key-pair"
grafana_admin_password = "your-secure-password"
```

### 2. Terraform 초기화

```bash
terraform init
```

### 3. 계획 확인

```bash
terraform plan
```

생성될 리소스:
- EC2 인스턴스 (t3.medium, 50GB)
- Elastic IP
- Security Group (HTTP, HTTPS, Prometheus)
- Security Group Rules (Dev, Staging Exporter 포트 허용)
- Route53 A 레코드 (monitoring.dev.devths.com)

### 4. 배포 실행

```bash
terraform apply
```

### 5. 출력 확인

```bash
terraform output
```

출력 예시:
```
grafana_url = "https://monitoring.dev.devths.com"
monitoring_public_ip = "52.79.123.456"
prometheus_url = "http://10.0.1.100:9090"
```

## 배포 후 작업

### 1. 모니터링 서버 상태 확인

```bash
# EC2에 SSM 세션으로 접속
aws ssm start-session --target <instance-id>

# Docker 컨테이너 상태 확인
cd /home/ubuntu/monitoring/non-prod
docker compose ps

# Prometheus 타겟 확인
curl http://localhost:9090/api/v1/targets | jq
```

### 2. API 서버에 Exporter 설치

각 Dev, Staging EC2에서 실행:

```bash
cd /path/to/Devths-Cloud/monitoring/scripts
sudo ./install-exporters.sh
```

### 3. Grafana 접속

브라우저에서 접속: `https://monitoring.dev.devths.com`
- Username: `admin`
- Password: terraform.tfvars에 설정한 비밀번호

### 4. Grafana 대시보드 Import

1. Dashboards → Import
2. Dashboard ID 입력:
   - **1860**: Node Exporter Full
   - **12708**: Nginx Exporter
3. Prometheus 데이터소스 선택
4. Import 클릭

## 주요 파일

### Terraform 설정
- `main.tf`: 리소스 정의
- `variables.tf`: 변수 정의
- `outputs.tf`: 출력 정의
- `terraform.tfvars`: 변수 값 (gitignore)

### 모니터링 설정 파일 (EC2 인스턴스 내)
- `/home/ubuntu/monitoring/non-prod/docker-compose.yml`
- `/home/ubuntu/monitoring/non-prod/prometheus/prometheus.yml`
- `/home/ubuntu/monitoring/non-prod/prometheus/alerts/alert-rules.yml`
- `/home/ubuntu/monitoring/non-prod/grafana/provisioning/datasources.yml`

## 모니터링 대상

### Dev 환경
- Node Exporter: `<dev-private-ip>:9100`
- Nginx Exporter: `<dev-private-ip>:9113`

### Staging 환경
- Node Exporter: `<staging-private-ip>:9100`
- Nginx Exporter: `<staging-private-ip>:9113`

## Security Group 규칙

### 모니터링 서버 (인바운드)
- Port 80 (HTTP): 0.0.0.0/0
- Port 443 (HTTPS): 0.0.0.0/0
- Port 9090 (Prometheus): VPC CIDR

### API 서버 (추가된 규칙)
- Port 9100 (Node Exporter): 모니터링 서버 SG
- Port 9113 (Nginx Exporter): 모니터링 서버 SG

## 업데이트 및 재배포

### 모니터링 대상 IP 변경 시

Dev 또는 Staging 서버의 Private IP가 변경된 경우:

```bash
terraform plan
terraform apply
```

Terraform이 자동으로 새로운 IP를 감지하고 Prometheus 설정을 업데이트합니다.

### 설정 파일 수정 시

User data 스크립트나 모니터링 설정을 변경한 경우:

```bash
# 인스턴스 재생성 필요
terraform taint module.monitoring.aws_instance.monitoring
terraform apply
```

## 비용 최적화

### 인스턴스 타입 조정

```hcl
# terraform.tfvars
instance_type = "t3.small"  # 비용 절감 (최소 권장: t3.small)
```

### 볼륨 크기 조정

```hcl
# terraform.tfvars
root_volume_size = 30  # 기본 50GB에서 축소
```

### Prometheus 데이터 보존 기간

모듈에서 자동 설정:
- Non-Prod: 30일
- Prod: 90일

## 문제 해결

### 문제: Grafana 접속 불가

**원인**: SSL 인증서 미발급

**해결**:
```bash
# EC2에 접속
sudo certbot --nginx -d monitoring.dev.devths.com
```

### 문제: Prometheus 타겟 DOWN

**원인**: Security Group 규칙 누락

**해결**:
```bash
# Terraform으로 Security Group 규칙 재적용
terraform apply -auto-approve

# API 서버에서 Exporter 상태 확인
sudo systemctl status node_exporter
sudo systemctl status nginx_exporter
```

### 문제: Dev/Staging IP 변경 감지 안됨

**원인**: Terraform state 동기화 문제

**해결**:
```bash
# State 갱신
terraform refresh

# 재배포
terraform apply
```

## 리소스 삭제

```bash
# 모든 리소스 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=module.monitoring
```

**주의**: 삭제 시 Prometheus 데이터와 Grafana 대시보드가 모두 삭제됩니다. 백업 필요 시 사전에 수행하세요.

## 참고 문서

- 모니터링 시스템 전체 가이드: `/monitoring/README.md`
- 빠른 시작 가이드: `/monitoring/QUICKSTART.md`
- Terraform 모듈 문서: `/terraform/modules/monitoring/`
