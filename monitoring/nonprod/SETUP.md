# Nonprod 모니터링 스택 설정 가이드

> **대상 환경**: Dev / Staging 공용 모니터링
> **최종 수정**: 2026-03-20
> **작성 목적**: 초기 구축 이력, 발생했던 오류와 수정 내용, 운영 전제조건을 처음 보는 사람도 이해할 수 있도록 기록

---

## 1. 전체 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────┐
│                    K8s Cluster (nonprod)                     │
│                                                             │
│  ┌──────────┐   remote_write   ┌──────────────────────┐    │
│  │Prometheus│ ────────────────▶│  EC2 Prometheus      │    │
│  │(in-cluster│  (2h 단기보관)   │  (30d 장기보관)       │    │
│  │ 2h TTL)  │                  └──────────────────────┘    │
│  └──────────┘                           │                   │
│       ▲                                 ▼                   │
│  node-exporter                  ┌──────────────────────┐    │
│  kube-state-metrics             │  Alertmanager        │    │
│                                 └──────────┬───────────┘    │
│  ┌──────────┐   push logs      ┌──────────▼───────────┐    │
│  │  Alloy   │ ────────────────▶│  Loki (S3 백엔드)     │    │
│  │(DaemonSet│                  │  NodePort: 30100      │    │
│  │ 3 nodes) │                  └──────────────────────┘    │
│  │          │   forward traces │                            │
│  │          │ ────────────────▶│  Tempo (S3 백엔드)    │    │
│  └──────────┘                  │  NodePort: 32200      │    │
│       ▲                        └──────────────────────┘    │
│  App pods                                                   │
│  (OTLP → Alloy:4317/4318)                                   │
└─────────────────────────────────────────────────────────────┘
          NodePort 30100 (Loki) │ NodePort 32200 (Tempo)
                                ▼
                    ┌───────────────────────┐
                    │  EC2 Grafana          │
                    │  (docker-compose)     │
                    │  - Prometheus DS      │
                    │  - Loki DS            │
                    │  - Tempo DS           │
                    └───────────────────────┘
```

### 컴포넌트별 역할

| 컴포넌트 | 위치 | 역할 |
|---------|------|------|
| **Alloy** (DaemonSet) | K8s 전 노드 | Pod stdout 로그 수집 → Loki, OTLP 트레이스 수신 → Tempo |
| **Loki** (SingleBinary) | K8s | 로그 저장. 청크 → S3, 인덱스 → S3(tsdb) |
| **Tempo** (monolithic) | K8s | 트레이스 저장 → S3 |
| **in-cluster Prometheus** | K8s | K8s 메트릭 수집(2h) → EC2 remote_write |
| **EC2 Prometheus** | EC2 docker-compose | 장기 메트릭 보관(30d), DB EC2 직접 스크래핑 |
| **EC2 Alertmanager** | EC2 docker-compose | 알람 수신 → Discord 웹훅 |
| **EC2 Grafana** | EC2 docker-compose | 대시보드. Prometheus/Loki/Tempo 통합 조회 |

---

## 2. 설치 전 사전 조건

### 2-1. K8s 클러스터 (마스터 노드에서 실행)

```bash
# kubectl 연결 확인
kubectl get nodes

# helm 설치 여부 확인
helm version

# AWS CLI 설치 여부 확인 (SSM 접근용)
aws --version

# AWS CLI 없는 경우 설치
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

### 2-2. EC2 모니터링 서버 (docker-compose 실행 서버)

```bash
# docker 설치 여부 확인
docker --version
docker compose version

# ubuntu 사용자를 docker 그룹에 추가 (permission denied 방지)
sudo usermod -aG docker ubuntu && newgrp docker

# AWS CLI 설치 (setup-env.sh SSM 접근용)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

### 2-3. SSM Parameter Store 등록 필요 값

아래 파라미터가 사전에 등록되어 있어야 합니다.

| SSM 경로 | 용도 | 비고 |
|---------|------|------|
| `/Dev/Monitoring/EC2_PRIVATE_IP` | 모니터링 EC2 Private IP | remote_write 대상 주소 |
| `/Dev/Monitoring/LOKI_S3_BUCKET_NAME` | Loki S3 버킷명 | Terraform output에서 확인 |
| `/Dev/Monitoring/TEMPO_S3_BUCKET_NAME` | Tempo S3 버킷명 | Terraform output에서 확인 |
| `/Dev/Monitoring/GF_USER` | Grafana 관리자 계정명 | |
| `/Dev/Monitoring/GF_PASSWORD` | Grafana 관리자 비밀번호 | SecureString |
| `/Dev/Monitoring/GF_URL` | Grafana 외부 접근 URL | `http://<EC2-IP>:3000` |
| `/Dev/Monitoring/GF_DOMAIN` | Grafana 도메인 | EC2 IP 또는 도메인 |
| `/Dev/Monitoring/DISCORD_WEBHOOK_NONPROD` | Discord 알람 웹훅 URL | SecureString |

등록 예시:
```bash
aws ssm put-parameter --name "/Dev/Monitoring/GF_URL" \
  --value "http://172.16.10.67:3000" --type String --region ap-northeast-2

aws ssm put-parameter --name "/Dev/Monitoring/GF_PASSWORD" \
  --value "yourpassword" --type SecureString --region ap-northeast-2
```

### 2-4. IAM 권한 (K8s 노드 instance profile)

Loki와 Tempo가 S3에 접근하려면 K8s 워커 노드의 IAM instance profile에 아래 권한이 있어야 합니다.

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::<loki-bucket-name>",
    "arn:aws:s3:::<loki-bucket-name>/*",
    "arn:aws:s3:::<tempo-bucket-name>",
    "arn:aws:s3:::<tempo-bucket-name>/*"
  ]
}
```

### 2-5. DB EC2 node-exporter (선택, 인프라 알람용)

EC2 Prometheus가 DB 서버 메트릭을 수집하려면 아래가 필요합니다.

**DB EC2에 node-exporter 설치:**
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/

sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target
[Service]
ExecStart=/usr/local/bin/node_exporter
Restart=always
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

**DB EC2 보안그룹에 인바운드 규칙 추가:**

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| Custom TCP | TCP | 9100 | 모니터링 EC2 SG 또는 172.16.10.67/32 |

node-exporter가 없거나 보안그룹이 막혀 있으면 `infrastructure.yml`의 DB 서버 관련 알람(CPU, 메모리, 디스크)이 절대 발동되지 않습니다.

### 2-6. BE ServiceMonitor (선택, 앱 알람용)

`alerts/backend-apps.yml`의 알람 규칙들(`http_server_requests_seconds_count`, `jvm_memory_used_bytes`, `hikaricp_connections_active`)은 Spring Boot Actuator 메트릭을 기반으로 합니다.
in-cluster Prometheus가 이 메트릭을 수집하려면 BE 네임스페이스에 ServiceMonitor 또는 PodMonitor가 있어야 합니다.

```bash
# ServiceMonitor 존재 여부 확인
kubectl get servicemonitor -n devths
```

ServiceMonitor가 없으면 BE 관련 알람 규칙은 메트릭이 없어서 동작하지 않습니다.
ServiceMonitor 추가는 `k8s-kustomize` 작업으로 별도 처리가 필요합니다.

---

## 3. 설치 방법

### 3-1. EC2 docker-compose (모니터링 EC2에서)

```bash
# 레포 클론 (최초 1회)
git clone https://github.com/100-hours-a-week/9-team-Devths-CLOUD.git
cd 9-team-Devths-CLOUD/monitoring/nonprod

# SSM에서 .env 파일 생성
chmod +x setup-env.sh && ./setup-env.sh

# docker-compose 실행
docker compose up -d

# 상태 확인
docker compose ps
```

### 3-2. K8s Helm 스택 (마스터 노드에서)

#### 최초 설치

```bash
cd 9-team-Devths-CLOUD/k8s-helm/releases/monitoring
chmod +x install.sh && ./install.sh
```

#### 재설치 (설정 변경 후)

> ⚠️ **중요**: Loki, Tempo, Prometheus는 StatefulSet 기반입니다.
> K8s StatefulSet의 `volumeClaimTemplates` 필드는 **변경 불가(immutable)**합니다.
> persistence 설정 등 StatefulSet spec이 변경된 경우, `helm upgrade`가 아래 오류와 함께 실패합니다:
> ```
> spec.volumeClaimTemplates: Forbidden: updates to statefulset spec for fields other than replicas...
> ```
>
> 이 경우 아래 순서로 기존 릴리즈를 완전히 삭제 후 재설치해야 합니다.

```bash
# 기존 Helm 릴리즈 삭제
helm uninstall loki tempo kube-prometheus-stack -n monitoring

# 남아있는 PVC 삭제 (중요: 남겨두면 새 설치에서 재사용 시도로 오류 발생)
kubectl delete pvc --all -n monitoring

# 재설치
./install.sh
```

---

## 4. NodePort IP 주의사항

Grafana datasource(`grafana/provisioning/datasources/datasources.yml`)에 Loki와 Tempo NodePort 주소가 하드코딩되어 있습니다.

```yaml
- name: Loki
  url: http://172.16.10.177:30100   # 마스터 노드 Private IP

- name: Tempo
  url: http://172.16.10.177:32200   # 마스터 노드 Private IP
```

마스터 노드 IP가 변경되면 Grafana에서 로그/트레이스 조회가 단절됩니다.
마스터 노드에 Elastic IP가 할당되어 있거나 VPC에서 고정 IP를 사용하는 경우에는 문제없습니다.
IP가 동적 할당이라면 변경 시 이 파일을 수동으로 업데이트하고 Grafana를 재시작해야 합니다.

```bash
# Grafana datasource 재로드 (컨테이너 재시작)
docker compose restart grafana
```

---

## 5. 발생했던 오류 이력 및 수정 내용

구축 과정에서 발생한 오류들을 순서대로 기록합니다.

---

### [오류 1] AWS CLI 미설치

**발생 위치**: EC2 모니터링 서버에서 `./setup-env.sh` 실행 시

**오류 메시지**:
```
aws: command not found
```

**원인**: EC2 userdata에 AWS CLI 설치가 포함되지 않아 수동 설치 필요

**해결**:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

---

### [오류 2] SSM 파라미터 미등록

**발생 위치**: EC2에서 `./setup-env.sh` 실행 시

**오류 메시지**:
```
ParameterNotFound
```

**원인**: `/Dev/Monitoring/GF_URL` 등 일부 SSM 파라미터가 등록되지 않은 상태에서 스크립트 실행

**해결**: 누락된 파라미터 개별 등록
```bash
aws ssm put-parameter --name "/Dev/Monitoring/GF_URL" \
  --value "http://172.16.10.67:3000" --type String --region ap-northeast-2
```

---

### [오류 3] Docker permission denied

**발생 위치**: EC2에서 `docker compose up` 실행 시

**오류 메시지**:
```
permission denied while trying to connect to the Docker daemon socket
```

**원인**: ubuntu 사용자가 docker 그룹에 포함되지 않음

**해결**:
```bash
sudo usermod -aG docker ubuntu && newgrp docker
```

---

### [오류 4] git pull 실패 (install.sh 로컬 변경)

**발생 위치**: 마스터 노드에서 `git pull` 시

**오류 메시지**:
```
error: Your local changes to the following files would be overwritten by merge:
    k8s-helm/releases/monitoring/install.sh
```

**원인**: 마스터 노드에서 `chmod +x install.sh`를 실행하면 git이 파일 권한 변경을 추적하여 로컬 변경 사항으로 인식

**해결**:
```bash
git checkout k8s-helm/releases/monitoring/install.sh
git pull
```

또는 git의 파일 권한 추적을 비활성화:
```bash
git config core.fileMode false
```

---

### [오류 5] Loki 설치 실패 — envsubst 플레이스홀더 오류

**발생 위치**: 마스터 노드에서 `./install.sh` → Loki 설치 단계

**오류 메시지**:
```
Error: execution error at (loki/templates/validate.yaml):
Please define loki.storage.bucketNames.chunks
```

**원인**: `values-loki.yaml`의 버킷명 플레이스홀더가 `LOKI_S3_BUCKET_NAME` (중괄호 없음) 형태로 작성되어 `envsubst`가 치환하지 못한 채로 helm에 전달됨

**수정 전**:
```yaml
bucketNames:
  chunks: LOKI_S3_BUCKET_NAME
```

**수정 후**:
```yaml
bucketNames:
  chunks: ${LOKI_S3_BUCKET_NAME}
```

`envsubst`는 반드시 `${VAR_NAME}` 형식이어야 치환됩니다.

---

### [오류 6] Loki 설치 실패 — bucketNames 위치 오류

**발생 위치**: 플레이스홀더 수정 후 재설치 시 동일 오류

**오류 메시지**:
```
Error: execution error at (loki/templates/validate.yaml):
Please define loki.storage.bucketNames.chunks
```

**원인**: Loki Helm 차트 v6+에서는 `bucketNames`가 `loki.storage` 직하위에 있어야 합니다. 기존 설정에서 `loki.storage.s3` 하위에 위치해 있어 차트가 인식하지 못함

**수정 전**:
```yaml
loki:
  storage:
    type: s3
    s3:
      bucketNames:        # ❌ 잘못된 위치
        chunks: ${LOKI_S3_BUCKET_NAME}
      region: ap-northeast-2
```

**수정 후**:
```yaml
loki:
  storage:
    bucketNames:          # ✅ storage 직하위
      chunks: ${LOKI_S3_BUCKET_NAME}
      ruler: ${LOKI_S3_BUCKET_NAME}
      admin: ${LOKI_S3_BUCKET_NAME}
    type: s3
    s3:
      region: ap-northeast-2
```

---

### [오류 7] Loki 설치 실패 — SingleBinary와 SimpleScalable 충돌

**발생 위치**: bucketNames 수정 후 재설치 시

**오류 메시지**:
```
Error: execution error at (loki/templates/validate.yaml:31:4):
You have more than zero replicas configured for both the single binary
and simple scalable targets.
```

**원인**: Loki Helm 차트 v6+의 기본값에서 `read`, `write`, `backend` 컴포넌트(SimpleScalable 모드용)의 replicas가 0이 아닌 값으로 설정되어 있음. `deploymentMode: SingleBinary`로 설정해도 SimpleScalable 컴포넌트를 명시적으로 비활성화하지 않으면 충돌 오류 발생

**해결**: values 파일에 명시적으로 0 지정
```yaml
# SingleBinary 모드에서 SimpleScalable 컴포넌트 비활성화 (충돌 방지)
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0
```

---

### [오류 8] loki-0, tempo-0, prometheus-0 Pending — PVC 미바인드

**발생 위치**: Helm 설치 후 Pod 상태 확인 시

**오류 메시지** (`kubectl get events -n monitoring`):
```
Warning  FailedBinding  persistentvolumeclaim/storage-loki-0
  no persistent volumes available for this claim and no storage class is set

Warning  FailedScheduling  pod/loki-0
  0/3 nodes are available: pod has unbound immediate PersistentVolumeClaims
```

**원인**: 클러스터에 StorageClass가 없어 PVC 바인딩 불가. 애초에 Loki/Tempo는 S3를 백엔드로 사용하므로 로컬 PVC가 불필요한 구조인데, 기존 values 파일에 `persistence.enabled: true`가 설정되어 있었음

**해결**: 세 컴포넌트 모두 로컬 persistence 비활성화

```yaml
# values-loki.yaml
singleBinary:
  persistence:
    enabled: false  # S3를 백엔드로 사용하므로 로컬 PVC 불필요

# values-tempo.yaml
persistence:
  enabled: false  # S3를 백엔드로 사용하므로 로컬 PVC 불필요

# values-kube-prometheus-stack.yaml
prometheusSpec:
  storageSpec: {}  # emptyDir 사용 (2h 단기보관, remote_write → EC2 30d 보관)
```

> ⚠️ 이 변경 후 기존에 PVC와 함께 설치된 릴리즈는 `helm upgrade`로 적용 불가.
> StatefulSet VolumeClaimTemplates는 불변이므로 반드시 `helm uninstall` + `kubectl delete pvc` 후 재설치 필요.

---

### [오류 9] loki-chunks-cache-0 Pending — 리소스 부족

**발생 위치**: PVC 수정 후에도 loki-chunks-cache-0가 Pending

**오류 메시지**:
```
Warning  FailedScheduling  pod/loki-chunks-cache-0
  0/3 nodes are available: 1 Insufficient cpu, 2 Insufficient memory
```

**원인**: Loki Helm 차트가 SingleBinary 모드에서도 memcached 기반 chunks cache / results cache StatefulSet을 기본으로 생성함. 노드 리소스(t3.medium)가 부족해 스케줄링 실패

**해결**: 두 캐시 컴포넌트 명시적 비활성화
```yaml
# values-loki.yaml
chunksCache:
  enabled: false

resultsCache:
  enabled: false
```

---

### [오류 10] ArgoCD sync 실패 — ServiceMonitor CRD 없음

**발생 위치**: kube-prometheus-stack 설치 전에 ArgoCD가 앱 sync를 시도할 때

**오류 메시지** (ArgoCD UI):
```
no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
```

**원인**: ArgoCD가 BE/AI 네임스페이스의 ServiceMonitor 리소스를 동기화하려 했으나, kube-prometheus-stack이 설치되지 않은 상태여서 CRD 자체가 없음

**해결**: kube-prometheus-stack 먼저 설치하면 CRD가 등록되어 ArgoCD sync 정상화됨. `install.sh`가 kube-prometheus-stack을 첫 번째로 설치하는 것이 이 이유입니다.

---

## 6. 설정 파일 수정 이력

구축 과정에서 발견된 설정 오류와 수정 내용을 파일별로 정리합니다.

---

### 6-1. `k8s-helm/releases/monitoring/values-loki.yaml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| bucketNames 위치 | `loki.storage.s3.bucketNames` | `loki.storage.bucketNames` | Loki 차트 v6+ 스키마 요구사항 |
| 플레이스홀더 형식 | `LOKI_S3_BUCKET_NAME` | `${LOKI_S3_BUCKET_NAME}` | envsubst는 `${VAR}` 형식만 치환 |
| SimpleScalable 비활성화 | 없음 | `read/write/backend replicas: 0` | SingleBinary 모드 충돌 방지 |
| persistence | `enabled: true` | `enabled: false` | S3 백엔드로 PVC 불필요 |
| chunksCache | 없음(차트 기본=활성) | `enabled: false` | 리소스 부족으로 Pending 발생 |
| resultsCache | 없음(차트 기본=활성) | `enabled: false` | 리소스 부족으로 Pending 발생 |
| compactor retention | 없음 | `compactor.retention_enabled: true` | 이 값 없이는 `retention_period: 30d` 미적용, S3에 로그 무기한 축적 |

### 6-2. `k8s-helm/releases/monitoring/values-tempo.yaml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| 플레이스홀더 형식 | `TEMPO_S3_BUCKET_NAME` | `${TEMPO_S3_BUCKET_NAME}` | envsubst 치환 형식 |
| `tempo.receivers` 구조 | `tempo.receivers` + `tempo.distributor.receivers` 동시 정의 | `tempo.receivers` 단일 정의 | `tempo.receivers`가 차트가 K8s Service에 OTLP 포트를 추가하는 데 필요한 값. 두 블록 동시 정의 시 포트 충돌 위험 |
| frontend_address | `tempo-query-frontend:9095` | `localhost:9095` | `tempo-query-frontend`는 분산 배포에서만 존재하는 서비스명. monolithic 모드에서는 `localhost` 사용 |
| persistence | `enabled: true` | `enabled: false` | S3 백엔드로 PVC 불필요 |

### 6-3. `k8s-helm/releases/monitoring/values-kube-prometheus-stack.yaml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| 플레이스홀더 형식 | `MONITORING_EC2_PRIVATE_IP` | `${MONITORING_EC2_PRIVATE_IP}` | envsubst 치환 형식 |
| storageSpec | `volumeClaimTemplate` 10Gi PVC 요청 | `storageSpec: {}` (emptyDir) | StorageClass 없는 클러스터, 2h 단기보관이므로 PVC 불필요 |

### 6-4. `k8s-helm/releases/monitoring/values-alloy.yaml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| `__path__` source_labels | `namespace + pod_name` | `pod_uid + container_name` | 실제 K8s 로그 경로 구조는 `/var/log/pods/<ns>_<pod>_<uid>/<container>/0.log`. uid 기반이어야 정확히 매칭됨 |
| dockercontainers mount | `true` | `false` | 클러스터가 containerd 런타임 사용. `/var/lib/docker/containers` 경로가 없어 불필요 |

### 6-5. `k8s-helm/releases/monitoring/install.sh`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| envsubst 변수 범위 | `envsubst < file.yaml` | `envsubst '${VAR}' < file.yaml` | 변수 범위 미지정 시 셸의 모든 환경변수(`$HOME`, `$USER` 등)가 치환 대상이 됨 |
| NODE_IP 하드코딩 | 하드코딩된 IP 사용 | `kubectl get nodes`로 동적 조회 | 노드 IP 변경에 대응 |

### 6-6. `monitoring/nonprod/docker-compose.yml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| alertmanager restart 정책 | 없음 | `restart: unless-stopped` | 컨테이너 비정상 종료 시 자동 복구 |
| alertmanager command | `--config.file` 만 있음 | `--config.expand-env=true` 추가 | Alertmanager는 기본적으로 config 파일의 환경변수를 치환하지 않음. 이 플래그(v0.22+) 없이는 `${DISCORD_WEBHOOK_NONPROD}`가 그대로 웹훅 URL로 전송됨 |

### 6-7. `monitoring/nonprod/alertmanager/alertmanager.yml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| message 블록 스칼라 | `>-` (folded + strip) | `\|-` (literal + strip) | `>-`는 개행을 공백으로 치환해 Discord 메시지가 한 줄로 붙어서 출력됨 |

### 6-8. `monitoring/nonprod/grafana/provisioning/datasources/datasources.yml`

| 항목 | 수정 전 | 수정 후 | 이유 |
|------|---------|---------|------|
| Prometheus datasource uid | 없음 | `uid: prometheus` | Tempo의 `tracesToMetrics.datasourceUid: prometheus` 참조를 위해 필요. UID 미설정 시 Grafana가 랜덤 UID를 생성해 Trace → Metrics 연동이 동작하지 않음 |
| Loki datasource uid | 없음 | `uid: loki` | Tempo의 `tracesToLogsV2.datasourceUid: loki` 참조를 위해 필요. UID 미설정 시 Trace → Logs 연동 불가 |
| Tempo cross-link UID 참조 | `datasourceUid: Loki`, `datasourceUid: Prometheus` (대문자, 이름) | `datasourceUid: loki`, `datasourceUid: prometheus` (소문자, UID) | datasourceUid는 datasource 이름이 아닌 UID 값과 일치해야 함 |

---

## 7. 동작 확인 방법

### 7-1. K8s 스택 확인

```bash
# 모든 Pod Running 확인
kubectl get pods -n monitoring

# Loki 로그 확인
kubectl logs -n monitoring loki-0 | tail -20

# Tempo 로그 확인
kubectl logs -n monitoring tempo-0 | tail -20

# NodePort 서비스 확인
kubectl get svc -n monitoring | grep NodePort
```

### 7-2. EC2 docker-compose 확인

```bash
cd ~/9-team-Devths-CLOUD/monitoring/nonprod
docker compose ps
docker compose logs prometheus | tail -20
docker compose logs alertmanager | tail -20
docker compose logs grafana | tail -20
```

### 7-3. 연결 확인

```bash
# EC2에서 Loki NodePort 접근 확인
curl http://172.16.10.177:30100/ready

# EC2에서 Tempo NodePort 접근 확인
curl http://172.16.10.177:32200/ready

# EC2에서 in-cluster Prometheus remote_write 수신 확인
curl http://localhost:9090/-/healthy

# remote_write 수신 여부 (Prometheus UI → Status → Targets)
```

### 7-4. Grafana 데이터소스 확인

Grafana UI(http://<EC2-IP>:3000) → Configuration → Data Sources에서 각 데이터소스 "Test" 버튼으로 연결 확인

---

## 8. 자주 발생하는 문제 빠른 참조

| 증상 | 확인 명령 | 원인 |
|------|----------|------|
| Pod Pending | `kubectl describe pod <pod> -n monitoring` | PVC 미바인드, 리소스 부족, 톨러레이션 미설정 |
| Loki S3 오류 | `kubectl logs loki-0 -n monitoring` | IAM 권한 부족, 버킷명 오류 |
| Tempo 트레이스 미저장 | Alloy 로그 확인 | Tempo Service에 4317 포트 미노출 |
| Discord 알람 미전송 | `docker compose logs alertmanager` | `--config.expand-env=true` 미설정, 웹훅 URL 치환 실패 |
| Grafana Loki 연결 실패 | Grafana datasource test | NodePort IP 변경, Loki Pod 미기동 |
| Trace→Logs 연동 안 됨 | Grafana datasource 설정 | Loki datasource에 `uid: loki` 미설정 |
| BE 알람 미발동 | `kubectl get servicemonitor -n devths` | ServiceMonitor 없음 |
