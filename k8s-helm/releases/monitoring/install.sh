#!/bin/bash
# 모니터링 스택 Helm 설치 스크립트 (nonprod K8s)
# SSM Parameter Store에서 플레이스홀더 값을 가져와 envsubst로 치환 후 helm install
# 경로 규칙: /Nonprod/Monitoring/<KEY> (프로젝트 공통 /<Env>/<Service>/<KEY> 계층 방식)
#
# 사전 조건:
#   - kubectl 설정 완료 (nonprod K8s 클러스터 연결)
#   - helm 설치
#   - AWS CLI 설정 (SSM 접근 권한 필요)
#   - SSM 파라미터 등록 완료 (문서 10-5 참고)
#
# 사용법:
#   cd k8s-helm/releases/monitoring
#   ./install.sh

set -e

REGION="ap-northeast-2"
NAMESPACE="monitoring"
SSM_PREFIX="/Dev/Monitoring"

echo "SSM Parameter Store에서 값 가져오는 중... (prefix: ${SSM_PREFIX})"

export MONITORING_EC2_PRIVATE_IP=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/EC2_PRIVATE_IP" \
  --query "Parameter.Value" --output text --region $REGION)

export LOKI_S3_BUCKET_NAME=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/LOKI_S3_BUCKET_NAME" \
  --query "Parameter.Value" --output text --region $REGION)

export TEMPO_S3_BUCKET_NAME=$(aws ssm get-parameter \
  --name "${SSM_PREFIX}/TEMPO_S3_BUCKET_NAME" \
  --query "Parameter.Value" --output text --region $REGION)

echo "가져온 값:"
echo "  MONITORING_EC2_PRIVATE_IP: ${MONITORING_EC2_PRIVATE_IP}"
echo "  LOKI_S3_BUCKET_NAME: ${LOKI_S3_BUCKET_NAME}"
echo "  TEMPO_S3_BUCKET_NAME: ${TEMPO_S3_BUCKET_NAME}"
echo ""

# Helm repo 추가/업데이트
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

# 네임스페이스 생성 (이미 있어도 무시)
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 1. kube-prometheus-stack (in-cluster Prometheus + node-exporter + kube-state-metrics)
echo "kube-prometheus-stack 설치 중..."
envsubst < values-kube-prometheus-stack.yaml | helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace ${NAMESPACE} \
  --timeout 10m \
  -f -

# 2. Loki (로그 저장 → S3)
echo "Loki 설치 중..."
envsubst < values-loki.yaml | helm upgrade --install loki \
  grafana/loki \
  --namespace ${NAMESPACE} \
  --timeout 5m \
  -f -

# 3. Tempo (트레이스 저장 → S3)
echo "Tempo 설치 중..."
envsubst < values-tempo.yaml | helm upgrade --install tempo \
  grafana/tempo \
  --namespace ${NAMESPACE} \
  --timeout 5m \
  -f -

# 4. Alloy (로그 수집 + OTLP 수신 — envsubst 불필요, 플레이스홀더 없음)
echo "Alloy 설치 중..."
helm upgrade --install alloy \
  grafana/alloy \
  --namespace ${NAMESPACE} \
  --timeout 5m \
  -f values-alloy.yaml

echo ""
echo "설치 완료. Pod 상태 확인:"
kubectl get pods -n ${NAMESPACE}

echo ""
echo "NodePort 서비스 패치 (Loki: 30100, Tempo: 32200):"
kubectl patch svc loki -n ${NAMESPACE} -p '{"spec":{"type":"NodePort","ports":[{"port":3100,"nodePort":30100,"protocol":"TCP"}]}}'
kubectl patch svc tempo -n ${NAMESPACE} -p '{"spec":{"type":"NodePort","ports":[{"port":3200,"nodePort":32200,"protocol":"TCP"}]}}'

echo ""
echo "완료"
echo "  Loki NodePort:  http://172.16.10.177:30100"
echo "  Tempo NodePort: http://172.16.10.177:32200"
