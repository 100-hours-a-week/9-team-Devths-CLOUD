# Devths 테라폼 인프라

> **작성자**: david.lee (이도연) / 클라우드
> **최종 수정일**: 2026-02-03

## 📋 목차

- [개요](#개요)
- [디렉토리 구조](#디렉토리-구조)
- [사전 요구사항](#사전-요구사항)
- [시작하기](#시작하기)
- [모듈 설명](#모듈-설명)
- [환경별 설정](#환경별-설정)
- [주요 리소스](#주요-리소스)
- [배포 프로세스](#배포-프로세스)

## 개요

Devths 프로젝트의 AWS 인프라를 Terraform으로 관리하는 Infrastructure as Code (IaC) 저장소입니다.

### 주요 특징

- **멀티 환경 지원**: Dev, Staging, Production 환경 분리
- **모듈화된 구조**: 재사용 가능한 Terraform 모듈
- **보안 강화**: KMS 암호화, SSM Parameter Store를 통한 시크릿 관리
- **자동화된 배포**: GitHub Actions와 CodeDeploy 통합
- **DNS 관리**: Route53을 통한 도메인 및 서브도메인 관리

## 디렉토리 구조

```
terraform/
├── README.md                    # 이 문서
├── environments/                # 환경별 설정
│   ├── dev/                     # 개발 환경
│   │   ├── main.tf              # 메인 설정 파일
│   │   ├── variables.tf         # 변수 정의
│   │   ├── outputs.tf           # 출력 값
│   │   └── ssm-params.tfvars    # SSM 파라미터 값
│   ├── staging/                 # 스테이징 환경
│   └── prod/                    # 프로덕션 환경
├── modules/                     # 재사용 가능한 모듈
│   ├── vpc/                     # VPC 및 네트워크 리소스
│   ├── ec2/                     # EC2 인스턴스
│   ├── iam/                     # IAM 역할 및 정책
│   ├── s3/                      # S3 버킷
│   ├── route53/                 # Route53 DNS 레코드
│   ├── codedeploy/              # CodeDeploy 리소스
│   └── ssm_parameters/          # SSM Parameter Store & KMS
└── shared/                      # 환경 간 공유 리소스
    ├── github-actions/          # GitHub Actions IAM 유저
    ├── route53/                 # Route53 Hosted Zone
    └── ssm/                     # 공유 SSM 파라미터
```

## 사전 요구사항

### 필수 도구

- **Terraform**: >= 1.0
- **AWS CLI**: 최신 버전
- **AWS 계정**: 적절한 권한을 가진 IAM 사용자 또는 역할

### AWS 권한

다음 AWS 서비스에 대한 권한이 필요합니다:
- VPC, EC2, EIP
- IAM (역할, 정책, 인스턴스 프로파일)
- S3
- Route53
- CodeDeploy
- SSM Parameter Store
- KMS

### 환경 변수 설정

## 시작하기

### 1. Route53 Hosted Zone 생성 (선택적, 도메인 사용 시)

도메인(`devths.com`)을 사용할 경우 먼저 Route53 Hosted Zone을 생성합니다:

```bash
cd shared/route53
terraform init
terraform plan
terraform apply

# Name Server 확인
terraform output name_servers
```

출력된 Name Server를 도메인 등록업체(가비아, AWS Route53 등)에 설정합니다.

### 2. GitHub Actions IAM 유저 생성 (최초 1회)

CI/CD를 위한 IAM 유저를 생성합니다:

```bash
cd shared/github-actions
terraform init
terraform plan
terraform apply
```

### 3. 환경별 인프라 배포

#### 개발 환경 배포

```bash
cd environments/dev

# Terraform 초기화
terraform init

# 실행 계획 확인
terraform plan

# 인프라 배포
terraform apply

# 출력 값 확인
terraform output
```

#### 스테이징/프로덕션 환경 배포

```bash
cd environments/staging  # 또는 prod
terraform init
terraform plan
terraform apply
```

**참고**:
- Dev/Staging 환경은 Elastic IP를 사용하지 않으며(`enable_eip = false`), Route53 레코드는 EC2 Public IP 기준으로 생성됩니다 (IP 변경 시 `terraform apply` 재실행 필요)
- Production 환경은 Elastic IP를 사용하여(`enable_eip = true`) 고정 IP 기반으로 Route53 레코드를 생성합니다

### 4. SSM Parameter 값 설정

인프라 배포 후, AWS Console 또는 AWS CLI로 SSM Parameter 값을 설정해야 합니다:

```bash
ssm-params.tfvar를 생성하여 해당 변수를 넣어둡니다.
```

## 모듈 설명

### VPC 모듈 (`modules/vpc`)

VPC, 서브넷, 인터넷 게이트웨이, 라우팅 테이블, 보안 그룹을 생성합니다.

**주요 리소스:**
- VPC (DNS 지원 활성화)
- Public 서브넷 (Multi-AZ)
- Private 서브넷 (Multi-AZ)
- Internet Gateway
- Route Tables
- Security Groups (HTTP/HTTPS 허용)

### EC2 모듈 (`modules/ec2`)

Ubuntu 22.04 기반의 EC2 인스턴스를 생성하고 초기 설정을 수행합니다.

**주요 기능:**
- 최신 Ubuntu 22.04 AMI 자동 선택
- User Data 스크립트를 통한 초기 설정
  - CodeDeploy Agent 설치
  - 데이터베이스 초기화
  - Logrotate 설정
- Elastic IP 할당 (선택적, Production 권장)

### IAM 모듈 (`modules/iam`)

EC2와 CodeDeploy에 필요한 IAM 역할 및 정책을 생성합니다.

**주요 역할:**
- **EC2 Role**: SSM, CodeDeploy, CloudWatch 권한
- **CodeDeploy Role**: 배포 작업 수행 권한
- **커스텀 정책**: SSM Parameter Store 및 KMS 복호화 권한

### S3 모듈 (`modules/s3`)

배포 아티팩트 및 저장소용 S3 버킷을 생성합니다.

**주요 기능:**
- 서버 측 암호화 (AES256)
- 버저닝 활성화
- 퍼블릭 액세스 차단
- 라이프사이클 정책 (구버전 자동 삭제)

**생성되는 버킷:**
- `{project_name}-artifact-{environment}`: CodeDeploy 아티팩트
- `{project_name}-{environment}`: 일반 스토리지

### Route53 모듈 (`modules/route53`)

도메인 및 서브도메인 DNS 레코드를 관리합니다.

**생성되는 레코드:**
- `dev.devths.com` → Frontend
- `dev.api.devths.com` → Backend API
- `dev.ai.devths.com` → AI Service

### CodeDeploy 모듈 (`modules/codedeploy`)

환경별 Deployment Group을 생성합니다. CodeDeploy Application(FE/BE/AI)은 `shared/codedeploy`에서 공통으로 생성합니다.

**배포 그룹:**
- `Devths-V2-FE-Dev-Group`: Frontend 배포
- `Devths-V2-BE-Dev-Group`: Backend 배포
- `Devths-V2-AI-Dev-Group`: AI 서비스 배포

**배포 설정:**
- In-place 배포 방식
- EC2 태그 기반 타겟팅
- 롤백 설정 (선택적)

### SSM Parameters 모듈 (`modules/ssm_parameters`)

민감한 설정 값을 안전하게 관리하기 위한 Parameter Store를 구성합니다.

**주요 기능:**
- KMS 키 자동 생성 및 암호화
- Backend 파라미터 (DB 정보, JWT, OAuth 등)
- AI 파라미터 (API 키, 서비스 URL 등)
- `lifecycle.ignore_changes`로 수동 업데이트 보호

## 환경별 설정

### Dev 환경

- **도메인**: `dev.devths.com`
- **인스턴스 타입**: `t3.medium` (또는 설정된 타입)
- **SSH**: 비활성화 (SSM Session Manager 사용)
- **자동 롤백**: 비활성화

### Staging 환경

- **도메인**: `stg.devths.com`
- Production 배포 전 테스트 환경

### Production 환경

- **도메인**: `devths.com`
- **www 레코드**: 활성화
- **자동 롤백**: 활성화
- **고가용성**: Multi-AZ 구성

### 시작법

```bash
terraform apply -var-file="secrets.tfvars" -var-file="ssm-params.tfvars"
```

## 주요 리소스

### 네트워크

| 리소스 | CIDR | 용도 |
|--------|------|------|
| VPC | 10.0.0.0/16 | 전체 네트워크 |
| Public Subnet 1 | 10.0.1.0/24 | EC2, NAT Gateway |
| Public Subnet 2 | 10.0.2.0/24 | Multi-AZ 지원 |
| Private Subnet 1 | 10.0.11.0/24 | DB, 내부 서비스 |
| Private Subnet 2 | 10.0.12.0/24 | Multi-AZ 지원 |



### 리소스 삭제

```bash
# 주의: 모든 리소스가 삭제됩니다!
terraform destroy
```
