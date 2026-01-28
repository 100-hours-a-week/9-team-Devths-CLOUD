#!/bin/bash
set -e

echo "Starting Database Initialization..."

# SSM Parameter Store에서 비밀번호 및 유저명 조회
REGION=${AWS_REGION:-"ap-northeast-2"}
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

DB_USERNAME=$(aws ssm get-parameter --name "/Prod/BE/DB_USERNAME" --with-decryption --region $REGION --query "Parameter.Value" --output text)
DB_PASSWORD=$(aws ssm get-parameter --name "/Prod/BE/DB_PASSWORD" --with-decryption --region $REGION --query "Parameter.Value" --output text)

# 값이 비어있지 않은 경우에만 실행
if [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ]; then
    echo "Creating PostgreSQL user and database..."
    
    # 1. 유저 생성
    # user creation might fail if exists, using ON_ERROR_STOP=0 or checking existence is better, but keeping simple for now
    sudo -u postgres psql -c "CREATE USER $DB_USERNAME WITH PASSWORD '$DB_PASSWORD';" || echo "User might already exist"
    
    # 2. devths DB 생성
    sudo -u postgres psql -c "CREATE DATABASE devths OWNER $DB_USERNAME;" || echo "Database might already exist"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE devths TO $DB_USERNAME;"
    
    echo "Database initialization complete."
else
    echo "Failed to retrieve DB credentials from SSM Parameter Store."
    exit 1
fi
