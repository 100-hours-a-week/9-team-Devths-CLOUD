#!/bin/bash
set -e

echo "Starting Database Initialization for ${environment_prefix} environment..."

# SSM Parameter Store에서 비밀번호 및 유저명 조회
REGION=$${AWS_REGION:-"ap-northeast-2"}
echo "Using AWS Region: $REGION"

# PostgreSQL 실행 대기 (최대 30초)
echo "Waiting for PostgreSQL to start..."
RETRIES=10
while ! sudo -u postgres pg_isready; do
    if [ $RETRIES -le 0 ]; then
        echo "PostgreSQL failed to start within timeout."
        exit 1
    fi
    echo "Waiting for PostgreSQL... ($RETRIES retries left)"
    sleep 3
    ((RETRIES--))
done
echo "PostgreSQL is ready."

# SSM Parameter Store에서 DB 설정 조회
echo "Retrieving database credentials from SSM Parameter Store..."
DB_USERNAME=$$(aws ssm get-parameter --name "/${environment_prefix}/BE/DB_USERNAME" --with-decryption --region $REGION --query "Parameter.Value" --output text)
DB_PASSWORD=$$(aws ssm get-parameter --name "/${environment_prefix}/BE/DB_PASSWORD" --with-decryption --region $REGION --query "Parameter.Value" --output text)
DB_URL=$$(aws ssm get-parameter --name "/${environment_prefix}/BE/DB_URL" --with-decryption --region $REGION --query "Parameter.Value" --output text)

# DB_URL에서 데이터베이스 이름 추출 (예: jdbc:postgresql://localhost:5432/devths -> devths)
DB_NAME=$$(echo "$DB_URL" | sed -n 's|.*/\([^/]*\)$|\1|p')

# 값이 비어있지 않은 경우에만 실행
if [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ] && [ -n "$DB_NAME" ]; then
    echo "Creating PostgreSQL user '$DB_USERNAME' and database '$DB_NAME'..."

    # 1. 유저 생성 (이미 존재하면 무시)
    sudo -u postgres psql -c "CREATE USER $DB_USERNAME WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "User '$DB_USERNAME' already exists, skipping creation"

    # 2. 데이터베이스 생성 (이미 존재하면 무시)
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USERNAME;" 2>/dev/null || echo "Database '$DB_NAME' already exists, skipping creation"

    # 3. 권한 부여
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USERNAME;"

    echo "Database initialization complete for ${environment_prefix} environment."
    echo "  - Database: $DB_NAME"
    echo "  - Owner: $DB_USERNAME"
else
    echo "Failed to retrieve DB credentials from SSM Parameter Store."
    echo "  - DB_USERNAME: $${DB_USERNAME:-(empty)}"
    echo "  - DB_PASSWORD: $${DB_PASSWORD:+(set)}$${DB_PASSWORD:-(empty)}"
    echo "  - DB_NAME: $${DB_NAME:-(empty)}"
    exit 1
fi
