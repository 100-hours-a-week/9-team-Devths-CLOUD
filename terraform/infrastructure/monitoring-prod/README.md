# Production 모니터링 환경 Terraform 설정

Prod VPC에 Prometheus + Grafana 모니터링 서버를 배포합니다. Production 환경 전용 모니터링입니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      Prod VPC                               │
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
│  ┌─────────────────────┐                                   │
│  │  Prod EC2           │                                   │
│  │  - node_exporter    │                                   │
│  │  - nginx_exporter   │                                   │
│  └─────────────────────┘                                   │
└─────────────────────────────────────────────────────────────┘
```

## 사전 요구사항

다음 리소스가 먼저 생성되어 있어야 합니다:

1. **Prod VPC** (Prod 환경 내에서 생성)
2. **Prod 환경** (`terraform/infrastructure/prod`)
3. **Route53 Hosted Zone** (`terraform/infrastructure/common/route53`)
4. **IAM 역할** (Prod 환경의 EC2 IAM 역할 재사용)

## 배포 순서

### 1. 변수 파일 생성

```bash
cd terraform/infrastructure/monitoring-prod
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

필수 변수 설정:
```hcl
key_name               = "your-ec2-key-pair"
grafana_admin_password = "your-secure-production-password"
```

**보안 권장사항**:
- Grafana 비밀번호는 최소 16자 이상, 복잡한 조합 사용
- 비밀번호는 AWS Secrets Manager 또는 환경 변수로 관리
- terraform.tfvars 파일은 절대 Git에 커밋하지 않음

### 2. Terraform 초기화

```bash
terraform init
```

### 3. 계획 확인

```bash
terraform plan
```

생성될 리소스:
- EC2 인스턴스 (t3.large, 100GB)
- Elastic IP
- Security Group (HTTP, HTTPS, Prometheus)
- Security Group Rules (Prod Exporter 포트 허용)
- Route53 A 레코드 (monitoring.devths.com)

### 4. 배포 실행

```bash
# Production 배포는 신중하게 진행
terraform apply

# 또는 자동 승인 (CI/CD 환경)
terraform apply -auto-approve
```

### 5. 출력 확인

```bash
terraform output
```

출력 예시:
```
grafana_url = "https://monitoring.devths.com"
monitoring_public_ip = "52.79.234.567"
prometheus_url = "http://10.1.1.100:9090"
```

## 배포 후 작업

### 1. 모니터링 서버 상태 확인

```bash
# EC2에 SSM 세션으로 접속
aws ssm start-session --target <instance-id>

# Docker 컨테이너 상태 확인
cd /home/ubuntu/monitoring/prod
docker compose ps

# Prometheus 타겟 확인
curl http://localhost:9090/api/v1/targets | jq

# Grafana 상태 확인
curl -k https://localhost:3001/api/health
```

### 2. API 서버에 Exporter 설치

Prod EC2에서 실행:

```bash
cd /path/to/Devths-Cloud/monitoring/scripts
sudo ./install-exporters.sh
```

### 3. Grafana 초기 설정

브라우저에서 접속: `https://monitoring.devths.com`

#### 3.1. 로그인
- Username: `admin`
- Password: terraform.tfvars에 설정한 비밀번호

#### 3.2. 추가 보안 설정
1. Configuration → Users → 불필요한 계정 삭제
2. Configuration → Settings:
   - Allow sign up: 비활성화
   - Anonymous access: 비활성화
3. 알람 채널 설정 (이메일, Slack 등)

#### 3.3. 대시보드 Import
1. Dashboards → Import
2. Dashboard ID 입력:
   - **1860**: Node Exporter Full
   - **12708**: Nginx Exporter
   - **3662**: Prometheus 2.0 Overview
3. Prometheus 데이터소스 선택
4. Import 클릭

### 4. Alert 테스트

```bash
# Prometheus Alert Rules 확인
curl http://localhost:9090/api/v1/rules | jq

# 특정 알람 테스트 (CPU 부하 생성)
stress --cpu 8 --timeout 60s
```

## 운영 환경 특화 설정

### Prometheus 설정

- **데이터 보존 기간**: 90일
- **Alert 임계값**: Non-Prod보다 엄격
- **스크랩 간격**: 15초

### Grafana 설정

- **회원가입**: 비활성화
- **익명 접근**: 비활성화
- **세션 타임아웃**: 기본값 사용

### Alert Rules (주요 차이점)

| 알람 | Non-Prod | Prod |
|------|----------|------|
| 5xx 에러 개수 | 10개/5분 | 5개/5분 |
| 5xx 에러 비율 | 5% | 2% |
| CPU 사용률 | 80% | 75%/90% |
| 인스턴스 다운 | 2분 | 1분 |

## Security Group 규칙

### 모니터링 서버 (인바운드)
- Port 80 (HTTP): 0.0.0.0/0 (SSL 인증서 발급용)
- Port 443 (HTTPS): 0.0.0.0/0 (또는 사무실 IP로 제한 권장)
- Port 9090 (Prometheus): VPC CIDR

### Prod API 서버 (추가된 규칙)
- Port 9100 (Node Exporter): 모니터링 서버 SG만
- Port 9113 (Nginx Exporter): 모니터링 서버 SG만

## 백업 및 복구

### Prometheus 데이터 백업

```bash
# EC2에 접속
cd /home/ubuntu/monitoring/prod

# 컨테이너 중지
docker compose down

# 데이터 백업
sudo tar -czf prometheus-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/prod_prometheus-data

# 컨테이너 재시작
docker compose up -d
```

### Grafana 대시보드 백업

```bash
# 방법 1: Grafana UI에서 Export
# Dashboards → Manage → 각 대시보드 → Export

# 방법 2: 볼륨 백업
sudo tar -czf grafana-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/prod_grafana-data
```

### 복구 절차

```bash
# 1. 컨테이너 중지
docker compose down

# 2. 데이터 복구
sudo tar -xzf prometheus-backup-YYYYMMDD.tar.gz -C /
sudo tar -xzf grafana-backup-YYYYMMDD.tar.gz -C /

# 3. 권한 설정
sudo chown -R ubuntu:ubuntu /home/ubuntu/monitoring

# 4. 컨테이너 재시작
docker compose up -d
```

## 고가용성 (HA) 고려사항

현재 구성은 단일 인스턴스입니다. HA가 필요한 경우:

1. **Multi-AZ 배포**
   - 여러 AZ에 Prometheus 인스턴스 배포
   - Thanos 또는 Cortex로 데이터 통합

2. **외부 저장소**
   - Prometheus Remote Write로 장기 저장소 연동
   - S3, InfluxDB, Elasticsearch 등

3. **Grafana HA**
   - RDS로 Grafana 데이터베이스 외부화
   - 여러 Grafana 인스턴스 + ALB

## 모니터링 및 알람

### CloudWatch 통합

모니터링 서버 자체도 모니터링:

```bash
# CloudWatch Agent 설치 확인
systemctl status amazon-cloudwatch-agent

# 메트릭 확인
aws cloudwatch get-metric-statistics \
  --namespace CWAgent/Production \
  --metric-name mem_used_percent \
  --dimensions Name=InstanceId,Value=<instance-id> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### SNS 알람 설정

Prometheus 알람을 SNS로 전송:

1. `terraform/infrastructure/common/sns` 모듈로 SNS Topic 생성
2. Alertmanager 설정 추가
3. Discord/Slack 연동

## 비용 관리

### 월 예상 비용 (서울 리전)

- EC2 t3.large: ~$70/월
- EBS 100GB gp3: ~$10/월
- EIP: ~$3.6/월 (사용 중이면 무료)
- 데이터 전송: 변동적
- **총 예상**: ~$80-100/월

### 비용 절감 방안

1. **예약 인스턴스**: 1년 약정 시 ~40% 절감
2. **Savings Plans**: 유연한 비용 절감
3. **스팟 인스턴스**: 권장하지 않음 (모니터링 중단 위험)

## 업데이트 및 재배포

### 모니터링 대상 IP 변경 시

Prod 서버의 Private IP가 변경된 경우:

```bash
terraform refresh
terraform plan
terraform apply
```

### 인스턴스 타입 변경

```hcl
# terraform.tfvars
instance_type = "t3.xlarge"  # 성능 향상
```

```bash
terraform apply
```

**주의**: 인스턴스 타입 변경 시 잠시 다운타임 발생

### 볼륨 확장

```hcl
# terraform.tfvars
root_volume_size = 150  # 100GB → 150GB
```

```bash
terraform apply

# EC2 내에서 파일시스템 확장
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1
```

## 문제 해결

### 문제: Grafana 접속 불가 (502 Bad Gateway)

**원인**: Grafana 컨테이너 미실행

**해결**:
```bash
cd /home/ubuntu/monitoring/prod
docker compose ps
docker compose logs grafana
docker compose restart grafana
```

### 문제: Prometheus 타겟 DOWN

**원인**: Security Group 규칙 또는 Exporter 미실행

**해결**:
```bash
# 1. Security Group 확인
terraform apply -auto-approve

# 2. Prod API 서버에서 Exporter 확인
sudo systemctl status node_exporter
sudo systemctl restart node_exporter
sudo netstat -tlnp | grep 9100

# 3. 네트워크 테스트
telnet <prod-api-private-ip> 9100
```

### 문제: 디스크 공간 부족

**해결**:
```bash
# Docker 정리
docker system prune -a -f

# 오래된 Prometheus 데이터 삭제 (주의!)
cd /var/lib/docker/volumes/prod_prometheus-data/_data
rm -rf data/*

# 볼륨 확장 (위 "볼륨 확장" 섹션 참고)
```

## 리소스 삭제

```bash
# 삭제 전 백업 필수!
# Prometheus 데이터 백업
# Grafana 대시보드 백업

# 모든 리소스 삭제
terraform destroy

# 확인 후 yes 입력
```

**주의**:
- 삭제 시 90일치 Prometheus 데이터가 모두 삭제됩니다
- Grafana 대시보드와 설정이 모두 삭제됩니다
- Route53 레코드와 EIP도 삭제됩니다

## 참고 문서

- 모니터링 시스템 전체 가이드: `/monitoring/README.md`
- 빠른 시작 가이드: `/monitoring/QUICKSTART.md`
- Terraform 모듈 문서: `/terraform/modules/monitoring/`
- Non-Prod 모니터링: `/terraform/infrastructure/monitoring-nonprod/README.md`

## 지원 및 문의

- **GitHub Issues**: https://github.com/your-org/Devths-Cloud/issues
- **Slack**: #devths-monitoring-prod
- **Email**: devops@devths.com

---

**마지막 업데이트**: 2026-02-04
