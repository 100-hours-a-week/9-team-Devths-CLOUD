# IAM Groups and Users

이 모듈은 IAM 그룹, 개발자 계정, 서비스 계정을 관리합니다.

## 생성되는 리소스

### IAM 그룹
- `developers`: 개발자 그룹 (콘솔 로그인, MFA 강제)
- `service-accounts`: 서비스 계정 그룹 (프로그래밍 방식 접근만)

### IAM 사용자

#### 개발자 계정 (developers 그룹)
- `yun` - 콘솔 로그인 활성화, 초기 비밀번호 강제 변경
- `neon` - 콘솔 로그인 활성화, 초기 비밀번호 강제 변경
- `estar` - 콘솔 로그인 활성화, 초기 비밀번호 강제 변경

#### 서비스 계정 (service-accounts 그룹)
- `devths-s3-service-dev` - Dev 환경 S3 presigned URL 생성용
- `devths-s3-service-staging` - Staging 환경 S3 presigned URL 생성용
- `devths-s3-service-prod` - Production 환경 S3 presigned URL 생성용
- `devths-github-actions` - GitHub Actions CI/CD용 (infrastructure/common/github-actions에서 생성)

### IAM 정책 (고객 관리형)

#### developers 그룹 정책
1. **S3-Storage-ReadOnly**: Dev, Staging, Prod 환경의 storage S3 버킷에 대한 읽기 전용 접근
2. **SSM-Session-Manager-Access**: EC2 인스턴스에 대한 SSM Session Manager 접근
3. **MFA-Management**: 사용자가 자신의 MFA 디바이스를 관리할 수 있는 권한
4. **MFA-Force-Enforcement**: 비밀번호 변경 권한 및 MFA 미사용 시 다른 작업 차단
5. **Access-Key-Management**: 사용자가 자신의 Access Key를 관리할 수 있는 권한
6. **AmazonEC2ReadOnlyAccess** (AWS 관리형): EC2 인스턴스, VPC 등 읽기 전용

#### 서비스 계정 개별 정책
- **S3-Storage-Dev-FullAccess**: dev storage 버킷 전체 권한
- **S3-Storage-Staging-FullAccess**: staging storage 버킷 전체 권한
- **S3-Storage-Prod-FullAccess**: prod storage 버킷 전체 권한

## 배포 방법

### 1. GitHub Actions 사용자가 존재하는지 확인
```bash
cd terraform/infrastructure/common/github-actions
terraform apply
```

### 2. IAM Groups 배포
```bash
cd terraform/infrastructure/common/iam-groups
terraform init
terraform plan
terraform apply
```

### 3. 초기 비밀번호 확인
```bash
# 개발자 초기 비밀번호 확인 (터미널에만 표시, 로그에 기록되지 않음)
terraform output -json developer_initial_passwords | jq -r

# 또는 개별 확인
terraform output -raw developer_initial_passwords
```

**중요**: 초기 비밀번호는 안전하게 전달하고, 각 개발자에게 개별적으로 알려주세요.

## 개발자 첫 로그인 가이드

### 1. AWS 콘솔 로그인
1. AWS 콘솔 로그인 URL: https://[계정ID].signin.aws.amazon.com/console
2. IAM 사용자 이름: `yun`, `neon`, 또는 `estar`
3. 초기 비밀번호: Terraform output에서 확인한 비밀번호 입력

### 2. 비밀번호 변경
- 첫 로그인 시 자동으로 비밀번호 변경 화면이 나타남
- 새 비밀번호 입력 (AWS 비밀번호 정책 준수 필요)

### 3. MFA 설정 (필수!)
1. IAM > Users > [내 사용자 이름] > Security credentials
2. "Assign MFA device" 클릭
3. Virtual MFA device 선택
4. Google Authenticator 또는 Authy 앱 사용
5. QR 코드 스캔 후 연속된 두 개의 MFA 코드 입력

**MFA를 설정하지 않으면 거의 모든 AWS 작업이 차단됩니다!**

### 4. Access Key 생성 (로컬 개발용 - 선택사항)
1. IAM > Users > [내 사용자 이름] > Security credentials
2. "Create access key" 클릭
3. Use case: CLI 선택
4. Access Key ID와 Secret Access Key를 안전하게 저장

```bash
# ~/.aws/credentials에 추가
[devths]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

## 서비스 계정 Access Key 생성

### S3 서비스 계정 (로컬 개발용)

```bash
# Dev 환경용
aws iam create-access-key --user-name devths-s3-service-dev

# Staging 환경용
aws iam create-access-key --user-name devths-s3-service-staging

# Production 환경용 (매우 신중하게)
aws iam create-access-key --user-name devths-s3-service-prod
```

생성된 Access Key를 팀원들과 안전하게 공유하세요.

### 로컬 개발 환경 설정

```bash
# ~/.aws/credentials
[devths-dev]
aws_access_key_id = DEV_ACCESS_KEY
aws_secret_access_key = DEV_SECRET_KEY

[devths-staging]
aws_access_key_id = STAGING_ACCESS_KEY
aws_secret_access_key = STAGING_SECRET_KEY
```

애플리케이션에서 사용:
```bash
AWS_PROFILE=devths-dev python app.py  # dev 환경
AWS_PROFILE=devths-staging python app.py  # staging 환경
```

또는 환경 변수로:
```bash
export AWS_ACCESS_KEY_ID=DEV_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=DEV_SECRET_KEY
```

## 권한 상세

### developers 그룹 권한

#### S3 Storage 읽기 전용
- `devths-storage-dev` 버킷 읽기
- `devths-storage-staging` 버킷 읽기
- `devths-storage-prod` 버킷 읽기

#### EC2 읽기 전용
- EC2 인스턴스 정보 조회
- VPC, 서브넷, 보안 그룹 정보 조회
- AMI, 스냅샷 정보 조회

#### SSM Session Manager
- EC2 인스턴스에 대한 세션 시작/종료
- 인스턴스 정보 조회
- 세션 상태 확인

#### MFA 관리
- 자신의 MFA 디바이스 생성/삭제
- MFA 디바이스 활성화/비활성화
- MFA 디바이스 동기화

#### 비밀번호 및 MFA 강제
- 계정 정보 조회
- 자신의 비밀번호 변경
- **중요**: MFA가 활성화되지 않은 경우 대부분의 작업이 차단됨

#### Access Key 관리
- 자신의 Access Key 생성/삭제
- Access Key 목록 조회
- Access Key 활성화/비활성화

### service-accounts 그룹 권한

서비스 계정 그룹은 공통 정책이 없으며, 각 서비스 계정은 개별적으로 필요한 권한만 보유합니다.

- **S3 서비스 계정**: 각자 할당된 환경의 storage 버킷에 대한 전체 권한
- **GitHub Actions**: S3 artifact 버킷 및 CodeDeploy 배포 권한

## 보안 고려사항

### developers 그룹
1. **MFA 필수**: MFA를 활성화하지 않으면 거의 모든 AWS 작업이 차단됩니다.
2. **읽기 전용**: S3 storage 버킷과 EC2에 대한 쓰기/삭제 권한은 없습니다.
3. **콘솔 로그인**: 사람이 사용하는 계정이므로 콘솔 로그인이 활성화되어 있습니다.
4. **비밀번호 정책**: 첫 로그인 시 반드시 비밀번호를 변경해야 합니다.

### service-accounts 그룹
1. **프로그래밍 방식만**: 콘솔 로그인이 비활성화되어 있습니다.
2. **MFA 없음**: 자동화 도구가 사용하므로 MFA가 없습니다.
3. **최소 권한**: 각 계정은 자신의 환경/용도에 필요한 권한만 보유합니다.
4. **환경 분리**: dev, staging, prod 계정이 분리되어 있어 실수로 다른 환경에 접근할 수 없습니다.

## 출력값 확인

```bash
# 전체 출력 확인
terraform output

# 개발자 사용자 정보
terraform output developer_users

# 개발자 초기 비밀번호 (sensitive)
terraform output developer_initial_passwords

# S3 서비스 계정 정보
terraform output s3_service_accounts

# GitHub Actions 서비스 계정 정보
terraform output github_actions_service_account
```

## 주의사항

1. **초기 비밀번호는 안전하게 전달**: Terraform output은 sensitive로 표시되지만, 터미널 히스토리에 남을 수 있습니다.
2. **MFA 설정 강제**: 개발자들에게 첫 로그인 후 즉시 MFA를 설정하도록 안내하세요.
3. **Access Key 관리**: 서비스 계정의 Access Key는 주기적으로 로테이션하세요.
4. **Production 접근 제한**: Production S3 서비스 계정의 Access Key는 매우 신중하게 관리하세요.
5. **Account ID 확인**: `terraform.tfvars`에 올바른 AWS Account ID가 설정되어 있는지 확인하세요.

## 트러블슈팅

### "MFA required" 오류
- MFA를 활성화하지 않은 경우 발생
- IAM 콘솔에서 MFA 디바이스를 설정하세요

### 초기 비밀번호가 출력되지 않음
```bash
# Terraform state를 직접 확인
terraform state show aws_iam_user_login_profile.yun
```

### 서비스 계정이 버킷에 접근할 수 없음
- 올바른 환경의 서비스 계정을 사용하고 있는지 확인
- Access Key가 유효한지 확인
- S3 버킷 이름이 정확한지 확인
