# VPC Non-Production V2 (3-tier Architecture)

Docker 기반 애플리케이션을 위한 3-tier 아키텍처 VPC 구성

## 아키텍처 개요

```
10.1.0.0/16 (VPC)
│
├── Public Subnet (Web tier)
│   ├── 10.1.0.0/24 (ap-northeast-2a)
│   ├── 10.1.1.0/24 (ap-northeast-2c)
│   └── 리소스: ALB, NAT Gateway
│
├── Private Subnet (App tier)
│   ├── 10.1.10.0/24 (ap-northeast-2a)
│   ├── 10.1.11.0/24 (ap-northeast-2c)
│   └── 리소스: EC2 (Docker containers - FE/BE/AI)
│
└── Database Subnet (Data tier)
    ├── 10.1.20.0/24 (ap-northeast-2a)
    ├── 10.1.21.0/24 (ap-northeast-2c)
    └── 리소스: RDS PostgreSQL
```

## 주요 특징

### 네트워크 구성
- **Public Subnet**: 인터넷 게이트웨이로 직접 연결
- **Private Subnet**: NAT Gateway를 통한 아웃바운드 인터넷 접근
- **Database Subnet**: NAT Gateway를 통한 패치/업데이트 가능

### 보안 그룹
1. **ALB Security Group**
   - Inbound: HTTP(80), HTTPS(443) from 0.0.0.0/0
   - Outbound: All

2. **App Security Group**
   - Inbound: 3000(FE), 8080(BE), 8000(AI) from ALB SG
   - Outbound: All

3. **Database Security Group**
   - Inbound: 5432(PostgreSQL) from App SG
   - Outbound: All

### NAT 구성
- **NAT Instance 사용** (기본): 비용 최적화 (~$3/월)
  - t3.nano 인스턴스 사용
  - 개발/스테이징 환경에 적합
  - 단일 NAT Instance로 모든 AZ 커버
- **NAT Gateway 대안**: 고가용성 필요 시 `nat_type = "gateway"` (~$33/월)

## 사용 방법

### 1. 초기화
```bash
cd terraform/infrastructure/common/vpc-nonprod-v2
terraform init
```

### 2. 계획 확인
```bash
terraform plan
```

### 3. 배포
```bash
terraform apply
```

### 4. 출력 확인
```bash
terraform output
```

## 변수 커스터마이징

기본값을 변경하려면 `terraform.tfvars` 파일 생성:

```hcl
# 예시: NAT Gateway로 변경 (고가용성 필요 시)
nat_type = "gateway"
single_nat = false

# 예시: NAT 없이 구성 (완전 격리된 Private 서브넷)
nat_type = "none"

# 예시: NAT Instance 성능 향상 (트래픽 많을 경우)
nat_instance_type = "t3.small"

# 예시: 서브넷 CIDR 변경
private_subnet_cidrs = ["10.1.15.0/24", "10.1.16.0/24"]
```

## 비용 비교

| 구성 | 월 비용 | 용도 |
|------|---------|------|
| **NAT Instance (t3.nano)** | ~$3 | 개발/스테이징 (기본) |
| **NAT Instance (t3.small)** | ~$15 | 트래픽 많은 스테이징 |
| **Single NAT Gateway** | ~$33 | 프로덕션 (관리 편의) |
| **Multi-AZ NAT Gateway** | ~$66 | 프로덕션 (고가용성) |
| **NAT 없음** | $0 | 완전 격리 환경 |

**nonprod-v2는 NAT Instance (t3.nano)를 기본으로 사용**하여 비용 최적화

## 기존 VPC와의 차이점

| 항목 | vpc-nonprod (기존) | vpc-nonprod-v2 (신규) |
|------|-------------------|----------------------|
| **CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **Tier** | 2-tier | 3-tier |
| **NAT Gateway** | ❌ | ✅ |
| **DB Subnet** | ❌ | ✅ |
| **Security Groups** | EC2 only | ALB, App, DB |
| **용도** | V1 아키텍처 | Docker 기반 V2 |

## 주의사항

- 기존 `vpc-nonprod`는 그대로 유지됩니다
- 두 VPC는 독립적으로 운영됩니다
- VPC 피어링이나 Transit Gateway가 필요한 경우 별도 설정 필요

### NAT Instance 관련
- NAT Instance는 단일 장애점(SPOF)이 될 수 있음
- 프로덕션 환경에서는 NAT Gateway 권장
- NAT Instance가 중단되면 Private/DB 서브넷의 인터넷 접근 불가
- 자동 복구 설정은 포함되지 않음 (필요 시 Auto Scaling Group 구성)

## 다음 단계

1. VPC 생성 후 RDS 모듈 구성
2. EC2/ECS 모듈에서 이 VPC 참조
3. ALB 설정 및 Target Group 구성
4. Route53에서 ALB로 DNS 레코드 연결
