# Terraform Infrastructure for AWS

이 디렉토리에는 기존 AWS 인프라를 Terraform 코드로 변환한 내용이 포함되어 있습니다.


## 시작하기

### 1. 환경 변수 설정

민감한 정보(DB 비밀번호 등)를 설정하기 위해 `terraform.tfvars` 파일을 생성합니다:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` 파일을 편집하여 실제 값을 입력합니다:

```hcl
# AWS Configuration
aws_region     = "ap-northeast-2"
aws_account_id = "015932244909"

# Database Configuration
db_username = "your_actual_username"
db_password = "your_actual_secure_password"
```

**중요:** `terraform.tfvars` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.

### 2. Terraform 초기화

```bash
terraform init
```

### 3. 기존 AWS 리소스 Import

**중요:** 이 작업은 기존 AWS 리소스를 수정하거나 삭제하지 않습니다. 단지 Terraform state에 기존 리소스를 가져오는 작업입니다.

```bash
./import.sh
```

### 4. Import 확인

```bash
terraform plan
```

이 명령어는 Terraform 코드와 실제 AWS 리소스 간의 차이를 보여줍니다. 이상적으로는 차이가 없어야 합니다.

### 5. 차이 해결

만약 `terraform plan`에서 변경사항이 표시된다면:

1. Terraform 코드를 실제 AWS 리소스와 일치하도록 수정
2. 또는 의도적인 변경사항인 경우 `terraform apply`로 적용

## 주요 리소스

### VPC
- **devths_v1_dev** (vpc-07e8b2c8b4691f5c8): 개발 환경 VPC
- **devths_v1_prod** (vpc-0bb2d29ff2355366c): 프로덕션 환경 VPC

### EC2 인스턴스
- **devths-v1-dev** (i-0712de979cff43f0e): 개발 환경 인스턴스
- **devths-v1-prod** (i-064ee03d4e6886b10): 프로덕션 환경 인스턴스
- **devths-v1-stg** (i-01339ef7d558f7830): 스테이징 환경 인스턴스

### S3 버킷
- devths-artifact
- devths-artifact-prod
- devths-dev
- devths-dev-log
- devths-prod
- devths-ssm-log
- devths-staging
- do-not-delete-ssm-diagnosis-015932244909-ap-northeast-2-27k7d

### IAM 역할
- Devths-EC2-SSM
- Devths-EC2-Prod
- Devths-CodeDeploy
- Devths-CodeDeploy-Prod

### SSM Parameter Store
환경별(Dev/Prod/Stg)로 Backend 및 AI 서비스의 설정 파라미터를 관리합니다:
- **Backend Parameters**: DB 연결 정보, JWT 설정, OAuth 설정, S3 설정, CloudWatch 설정 등
- **AI Parameters**: API 키, 호스트 정보, LLM 설정, OCR 설정, Langfuse 설정 등

주요 파라미터 카테고리:
- `/Prod/BE/*` - 프로덕션 백엔드 설정 (23개 파라미터)
- `/Prod/AI/*` - 프로덕션 AI 서비스 설정 (12개 파라미터)
- `/Dev/BE/*` - 개발 백엔드 설정
- `/Dev/AI/*` - 개발 AI 서비스 설정
- `/Stg/BE/*` - 스테이징 백엔드 설정
- `/Stg/AI/*` - 스테이징 AI 서비스 설정

**Note**: 모든 파라미터는 `SecureString` 타입으로 암호화되어 저장됩니다.

### CodeDeploy
**Applications**:
- Devhts-V1-BE - 백엔드 애플리케이션
- Devhts-V1-FE - 프론트엔드 애플리케이션
- Devhts-V1-AI - AI 서비스 애플리케이션

**Deployment Groups** (각 애플리케이션당 3개 - Dev, Staging, Prod):
- BE: Dev-Group, Staging-Group, Prod-Group
- FE: Dev-Group, Staging-Group, Prod-Group
- AI: Dev-Group, Staging-Group, Prod-Group

### CloudWatch
**Log Groups**:
- `/aws/ec2/devths/api` - API 로그 (30일 보관)
- `/aws/ec2/devths/fe` - Frontend 로그 (30일 보관)
- `/aws/ec2/devths/ai` - AI 서비스 로그 (30일 보관)
- `/aws/ec2/devths/nginx/access` - Nginx Access 로그 (7일 보관)
- `/aws/ec2/devths/nginx/error` - Nginx Error 로그 (14일 보관)
- `/aws/lambda/devths-profanity-filter` - Lambda 로그 (7일 보관)

**Metric Filters**:
- API 5xx 에러 카운트
- Nginx 4xx/5xx 에러 카운트
- 비속어 감지 카운트

**Alarms**:
- High Error Rate (API 5xx > 10 in 5min)
- High CPU Utilization (> 80%)
- High Memory Utilization (> 85%)
- Low Disk Space (> 80%)
- Profanity Detection Alert (> 5 detections in 5min)

### Lambda Functions
**devths-profanity-filter** (신규):
- CloudWatch Logs에서 비속어를 실시간으로 감지하는 Lambda 함수
- Python 3.11 런타임
- API, Frontend, AI 로그 스트림을 모니터링
- 감지된 비속어를 CloudWatch Metrics로 전송

**Alert-Discord** (기존 - Import):
- Discord로 알림을 전송하는 Lambda 함수
- Node.js 24.x 런타임
- SNS Topic 'Discord'와 연결

**Alert-Discord-Prod** (기존 - Import):
- 프로덕션 환경 Discord 알림 Lambda 함수
- Node.js 24.x 런타임
- SNS Topic 'Discord-Prod'와 연결

### Route53
**Hosted Zone**: devths.com

**DNS Records**:
- Production: devths.com, www, api, ai (→ Elastic IP)
- Development: dev.devths.com, dev.api, dev.ai (→ 3.39.223.35)
- Staging: stg.devths.com, stg.api, stg.ai (→ 3.39.236.45)
- MX Record: 이메일 설정
- TXT Record: SPF 등 도메인 검증

### SNS Topics
- **Discord**: 개발/스테이징 환경 알림
- **Discord-Prod**: 프로덕션 환경 알림

## 주의사항

1. **민감한 정보 관리**:
   - `terraform.tfvars` 파일은 절대 Git에 커밋하지 마세요 (`.gitignore`에 포함됨)
   - DB 비밀번호 등 민감한 정보는 반드시 `terraform.tfvars`에 설정하세요
   - Parameter Store의 비밀번호는 SecureString으로 암호화되어 저장됩니다

2. **EC2 Key Pairs**: `ec2.tf` 파일에서 Key Pair의 `public_key` 값을 설정해야 합니다. 보안상 이 값은 코드에 포함되지 않았습니다.

3. **IAM 정책**: 사용자 정의 IAM 정책들은 별도로 정의해야 합니다. 현재는 기본 구조만 포함되어 있습니다.

4. **State 파일 관리**: `terraform.tfstate` 파일은 매우 중요합니다. 이 파일을 분실하면 리소스 관리가 어려워집니다. S3 백엔드 사용을 권장합니다.

5. **리소스 수정 전 확인**: 변경사항을 적용하기 전에 반드시 `terraform plan`으로 확인하세요.

## S3 Backend 설정 (권장)

State 파일을 안전하게 관리하기 위해 S3 backend를 설정하는 것을 권장합니다:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "devths/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
  }
}
```

## 트러블슈팅

### Import 실패
일부 리소스 import가 실패하는 경우, 해당 리소스 ID를 확인하고 수동으로 import하세요:

```bash
terraform import <resource_type>.<resource_name> <resource_id>
```

### Plan에서 차이가 계속 발생
일부 리소스 속성은 AWS API에서 반환되지 않거나 기본값이 다를 수 있습니다. 이 경우 `lifecycle` 블록의 `ignore_changes`를 사용하세요.

## 새로 추가된 기능

### 1. SSM Parameter Store 통합 관리
- 모든 환경(Dev/Prod/Stg)의 파라미터를 `for_each`로 관리
- `lifecycle { ignore_changes = [value] }` 설정으로 기존 값 보호
- Import 후 기존 값 유지

### 2. CodeDeploy 완전 통합
- 3개 애플리케이션 (BE/FE/AI)
- 9개 배포 그룹 (각 애플리케이션당 Dev/Staging/Prod)
- EC2 태그 기반 자동 배포 타겟 설정

### 3. CloudWatch 모니터링
- 애플리케이션별 로그 그룹
- 에러 추적을 위한 메트릭 필터
- 주요 지표에 대한 알람 설정

### 4. 비속어 필터링 시스템
- Lambda 기반 실시간 비속어 감지
- CloudWatch Logs Subscription Filter로 자동 트리거
- 한글 비속어 및 차별적 표현 감지
- 감지 결과를 CloudWatch Metrics로 전송

## SSM Parameter Import 방법

### 자동 Import (권장)

모든 SSM Parameter를 한 번에 import하는 스크립트를 제공합니다:

```bash
cd terraform
./scripts/import_ssm_parameters.sh
```

이 스크립트는 모든 환경(Dev/Prod/Stg)의 Backend 및 AI 파라미터를 자동으로 import합니다.

### 수동 Import

개별 파라미터를 수동으로 import할 수도 있습니다:

```bash
# Production Backend 파라미터 import 예시
terraform import 'aws_ssm_parameter.prod_be["DB_USERNAME"]' /Prod/BE/DB_USERNAME
terraform import 'aws_ssm_parameter.prod_be["DB_PASSWORD"]' /Prod/BE/DB_PASSWORD
terraform import 'aws_ssm_parameter.prod_be["JWT_SECRET"]' /Prod/BE/JWT_SECRET

# Production AI 파라미터 import 예시
terraform import 'aws_ssm_parameter.prod_ai["API_KEY"]' /Prod/AI/API_KEY
terraform import 'aws_ssm_parameter.prod_ai["GOOGLE_API_KEY"]' /Prod/AI/GOOGLE_API_KEY
```

**중요**: Import 후 `lifecycle.ignore_changes`로 인해 기존 파라미터 값이 보호됩니다.

## Lambda 배포

Lambda 함수는 자동으로 패키징되어 배포됩니다:

```bash
terraform apply
```

Lambda 코드를 수정한 경우:
```bash
terraform taint data.archive_file.lambda_profanity_filter
terraform apply
```

## 추가 작업 필요

1. **terraform.tfvars 설정**: 민감한 정보 설정 (SSM 파라미터 값은 import 후 자동으로 유지됨)
2. **EC2 Key Pair Public Keys**: public_key 값 설정
3. **Custom IAM Policies**: 사용자 정의 IAM 정책 정의
4. **S3 Bucket Policies**: S3 버킷 정책 정의 (필요한 경우)
5. **Tags**: 리소스 태그 검토 및 표준화
6. **SNS Topic**: CloudWatch 알람을 SNS로 전송하려면 SNS Topic 생성 필요

## 문의

Terraform 코드 관련 문의사항이 있으시면 팀에 문의하세요.
