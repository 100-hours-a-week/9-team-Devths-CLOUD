#!/bin/bash
set -e

echo "========================================"
echo "Database Initialization for ${environment_prefix} environment"
echo "========================================"

# SSM Parameter Store에서 비밀번호 및 유저명 조회
REGION=$${AWS_REGION:-ap-northeast-2}
echo "Using AWS Region: $$REGION"

# PostgreSQL 실행 대기 (최대 30초)
echo "Waiting for PostgreSQL to start..."
RETRIES=10
while ! sudo -u postgres pg_isready; do
    if [ $$RETRIES -le 0 ]; then
        echo "ERROR: PostgreSQL failed to start within timeout."
        exit 1
    fi
    echo "Waiting for PostgreSQL... ($$RETRIES retries left)"
    sleep 3
    RETRIES=$$(( RETRIES - 1 ))
done
echo "PostgreSQL is ready."

# SSM Parameter Store에서 DB 설정 조회
echo ""
echo "Retrieving database credentials from SSM Parameter Store..."
echo "  - Username path: /${environment_prefix}/BE/DB_USERNAME"
echo "  - Password path: /${environment_prefix}/BE/DB_PASSWORD"
echo "  - DB URL path: /${environment_prefix}/BE/DB_URL"

DB_USERNAME=$$( aws ssm get-parameter --name "/${environment_prefix}/BE/DB_USERNAME" --with-decryption --region $$REGION --query "Parameter.Value" --output text 2>&1 )
DB_USERNAME_STATUS=$$?

DB_PASSWORD=$$( aws ssm get-parameter --name "/${environment_prefix}/BE/DB_PASSWORD" --with-decryption --region $$REGION --query "Parameter.Value" --output text 2>&1 )
DB_PASSWORD_STATUS=$$?

DB_URL=$$( aws ssm get-parameter --name "/${environment_prefix}/BE/DB_URL" --with-decryption --region $$REGION --query "Parameter.Value" --output text 2>&1 )
DB_URL_STATUS=$$?

# SSM 조회 결과 확인
echo ""
echo "SSM Parameter retrieval status:"
echo "  - DB_USERNAME: $$DB_USERNAME_STATUS (0=success)"
echo "  - DB_PASSWORD: $$DB_PASSWORD_STATUS (0=success)"
echo "  - DB_URL: $$DB_URL_STATUS (0=success)"

if [ $$DB_USERNAME_STATUS -ne 0 ] || [ $$DB_PASSWORD_STATUS -ne 0 ] || [ $$DB_URL_STATUS -ne 0 ]; then
    echo ""
    echo "ERROR: Failed to retrieve parameters from SSM"
    [ $$DB_USERNAME_STATUS -ne 0 ] && echo "  - DB_USERNAME error: $$DB_USERNAME"
    [ $$DB_PASSWORD_STATUS -ne 0 ] && echo "  - DB_PASSWORD error: $$DB_PASSWORD"
    [ $$DB_URL_STATUS -ne 0 ] && echo "  - DB_URL error: $$DB_URL"
    exit 1
fi

# DB_URL에서 데이터베이스 이름 추출 (예: jdbc:postgresql://localhost:5432/devths -> devths)
DB_NAME=$$( echo "$$DB_URL" | sed -n 's|.*/\([^/?]*\).*|\1|p' )

echo ""
echo "Extracted database configuration:"
echo "  - Username: $$DB_USERNAME"
echo "  - Password: [REDACTED]"
echo "  - DB URL: $$DB_URL"
echo "  - DB Name: $$DB_NAME"

# 값이 비어있지 않은 경우에만 실행
if [ -z "$$DB_USERNAME" ] || [ -z "$$DB_PASSWORD" ] || [ -z "$$DB_NAME" ]; then
    echo ""
    echo "ERROR: One or more required values are empty"
    echo "  - DB_USERNAME: $${DB_USERNAME:-(empty)}"
    echo "  - DB_PASSWORD: $${DB_PASSWORD:+(set)}$${DB_PASSWORD:-(empty)}"
    echo "  - DB_NAME: $${DB_NAME:-(empty)}"
    exit 1
fi

echo ""
echo "Creating PostgreSQL user and database..."

# 1. 유저 생성 (이미 존재하면 무시)
echo "Creating user '$$DB_USERNAME'..."
if sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$$DB_USERNAME'" | grep -q 1; then
    echo "  - User '$$DB_USERNAME' already exists, skipping creation"
else
    sudo -u postgres psql -c "CREATE USER $$DB_USERNAME WITH PASSWORD '$$DB_PASSWORD';"
    echo "  - User '$$DB_USERNAME' created successfully"
fi

# 2. 데이터베이스 생성 (이미 존재하면 무시)
echo "Creating database '$$DB_NAME'..."
if sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$$DB_NAME'" | grep -q 1; then
    echo "  - Database '$$DB_NAME' already exists, skipping creation"
else
    sudo -u postgres psql -c "CREATE DATABASE $$DB_NAME OWNER $$DB_USERNAME;"
    echo "  - Database '$$DB_NAME' created successfully"
fi

# 3. 권한 부여
echo "Granting privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $$DB_NAME TO $$DB_USERNAME;"
echo "  - Privileges granted to '$$DB_USERNAME' on database '$$DB_NAME'"

echo ""
echo "========================================"
echo "Database initialization complete!"
echo "  - Environment: ${environment_prefix}"
echo "  - Database: $$DB_NAME"
echo "  - Owner: $$DB_USERNAME"
echo "========================================"
