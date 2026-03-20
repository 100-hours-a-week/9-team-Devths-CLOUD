#!/bin/bash
# Minimal userdata: SSM agent + Docker 설치만 수행
# 모니터링 스택 설정은 GitHub에서 clone 후 수동 진행1.

set -e

# Docker 설치
apt-get update -y
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker 서비스 활성화
systemctl enable docker
systemctl start docker

# SSM Agent 활성화 (Ubuntu 22.04 AWS AMI에 기본 설치됨)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
