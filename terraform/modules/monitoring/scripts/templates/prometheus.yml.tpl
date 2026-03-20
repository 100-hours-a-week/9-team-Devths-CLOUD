%{ if environment == "nonprod" ~}
global:
  scrape_interval: 30s
  evaluation_interval: 30s
  external_labels:
    cluster: 'devths-monitoring-nonprod'
    region: 'ap-northeast-2'
    environment: 'nonprod'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'alertmanager:9093'

rule_files:
  - '/etc/prometheus/alerts/*.yml'

scrape_configs:

  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']
        labels:
          env: 'nonprod'
          service: 'prometheus'

  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
        labels:
          env: 'nonprod'
          service: 'alertmanager'

%{ if k8s_mode ~}
  # =========================================================
  # K8s 모드: in-cluster Prometheus → remote_write 수신 담당
  # 서비스 메트릭은 ServiceMonitor → in-cluster Prometheus → remote_write로 수집됨
  # =========================================================

  # DB EC2 (172.16.10.81) node-exporter 직접 스크래프
  # K8s 외부 EC2이므로 static config 사용
  - job_name: 'db-ec2-node-exporter'
    scrape_interval: 30s
    static_configs:
      - targets: ['172.16.10.81:9100']
        labels:
          env: 'nonprod'
          service: 'node-exporter'
          instance_name: 'devths-V3-nonprod-DB'

%{ else ~}
  # =========================================================
  # EC2 모드: EC2 Service Discovery 기반 스크래프 (v2 환경)
  # =========================================================

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  # 개발 환경 - Node Exporter (EC2 서비스 디스커버리)
  - job_name: 'node-exporter-dev'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 9100
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [dev]
          - name: tag:Version
            values: [v2]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'dev'
      - target_label: service
        replacement: 'node-exporter'
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # 스테이징 환경 - Node Exporter (EC2 서비스 디스커버리)
  - job_name: 'node-exporter-staging'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 9100
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [stg]
          - name: tag:Version
            values: [v2]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'stg'
      - target_label: service
        replacement: 'node-exporter'
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # 개발 환경 - Spring Boot
  - job_name: 'spring-boot-dev'
    metrics_path: '/actuator/prometheus'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 8080
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [dev]
          - name: tag:Service
            values: [ Backend ]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:8080'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'dev'
      - target_label: service
        replacement: 'spring-boot'
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name

  # 스테이징 환경 - Spring Boot
  - job_name: 'spring-boot-staging'
    metrics_path: '/actuator/prometheus'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 8080
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [stg]
          - name: tag:Service
            values: [ Backend ]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:8080'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'stg'
      - target_label: service
        replacement: 'spring-boot'
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name

  # 개발 환경 - Next.js
  - job_name: 'nodejs-dev'
    metrics_path: '/api/metrics'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 3000
        filters:
          - name: tag:Project
            values: [ devths ]
          - name: tag:Environment
            values: [ dev ]
          - name: tag:Service
            values: [ Frontend ]
          - name: instance-state-name
            values: [ running ]
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        target_label: __address__
        replacement: '$${1}:3000'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'dev'
      - target_label: service
        replacement: 'nodejs'
      - source_labels: [ __meta_ec2_tag_Name ]
        target_label: instance_name

  # 스테이징 환경 - Next.js
  - job_name: 'nodejs-staging'
    metrics_path: '/api/metrics'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 3000
        filters:
          - name: tag:Project
            values: [ devths ]
          - name: tag:Environment
            values: [ stg ]
          - name: tag:Service
            values: [ Frontend ]
          - name: instance-state-name
            values: [ running ]
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        target_label: __address__
        replacement: '$${1}:3000'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'stg'
      - target_label: service
        replacement: 'nodejs'
      - source_labels: [ __meta_ec2_tag_Name ]
        target_label: instance_name

  # AI 서버 (v2 EC2)
  - job_name: 'ai-service'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 8000
        filters:
          - name: tag:Project
            values: [ devths ]
          - name: tag:Service
            values: [ Ai ]
          - name: tag:Version
            values: [ v2 ]
          - name: tag:Environment
            values: [ dev, stg, prod, nonprod ]
          - name: instance-state-name
            values: [ running ]
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        target_label: __address__
        replacement: '$${1}:8000'
      - source_labels: [ __meta_ec2_tag_Name, __meta_ec2_private_ip ]
        regex: '(.*);(.*)'
        target_label: instance
        replacement: '$${1} ($${2})'
      - source_labels: [ __meta_ec2_tag_Environment ]
        target_label: env

  # VectorDB (ChromaDB) EC2 (v2)
  - job_name: 'vectordb-ec2'
    scrape_interval: 15s
    scrape_timeout: 10s
    ec2_sd_configs:
      - region: ap-northeast-2
        refresh_interval: 1m
        port: 9100
        filters:
          - name: tag:Project
            values: [ devths ]
          - name: tag:Name
            values: [ devths-v2-dev-ai-vectorDB ]
          - name: instance-state-name
            values: [ running ]
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        target_label: __address__
        replacement: $${1}:9100
      - source_labels: [ __meta_ec2_tag_Name, __meta_ec2_private_ip ]
        regex: (.*);(.*)
        target_label: instance
        replacement: $${1} ($${2})
      - target_label: env
        replacement: dev
      - target_label: service
        replacement: vectordb
      - source_labels: [ __meta_ec2_tag_Name ]
        target_label: instance_name

%{ endif ~}

%{ else ~}
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'devths-monitoring-prod'
    region: 'ap-northeast-2'
    environment: 'production'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'alertmanager:9093'

rule_files:
  - '/etc/prometheus/alerts/*.yml'

scrape_configs:

  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']
        labels:
          env: 'prod'
          service: 'prometheus'

  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
        labels:
          env: 'prod'
          service: 'alertmanager'

%{ if k8s_mode ~}
  # =========================================================
  # K8s 모드: in-cluster Prometheus → remote_write 수신 담당
  # 서비스 메트릭은 ServiceMonitor → in-cluster Prometheus → remote_write로 수집됨
  # =========================================================

  # 프로덕션 K8s 전환 시 DB EC2 IP 업데이트 필요
  # - job_name: 'db-ec2-node-exporter'
  #   scrape_interval: 30s
  #   static_configs:
  #     - targets: ['<PROD_DB_IP>:9100']
  #       labels:
  #         env: 'prod'
  #         service: 'node-exporter'
  #         instance_name: 'devths-V3-prod-DB'

%{ else ~}
  # =========================================================
  # EC2 모드: EC2 Service Discovery 기반 스크래프 (v2 환경)
  # =========================================================

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  # V2 운영 환경 - Node Exporter (EC2 서비스 디스커버리)
  - job_name: 'node-exporter-v2-prod'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 9100
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [prod]
          - name: tag:Version
            values: [v2]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'prod'
      - target_label: service
        replacement: 'node-exporter'
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # V2 운영 환경 - Spring Boot (EC2 서비스 디스커버리)
  - job_name: 'spring-boot-v2-prod'
    metrics_path: '/actuator/prometheus'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 8080
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [prod]
          - name: tag:Service
            values: [ Backend ]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:8080'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'prod'
      - target_label: service
        replacement: 'spring-boot'
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name

  # 운영 환경 - Next.js (Node.js)
  - job_name: 'nodejs-prod'
    metrics_path: '/api/metrics'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 3000
        filters:
          - name: tag:Project
            values: [ devths ]
          - name: tag:Environment
            values: [ prod ]
          - name: tag:Service
            values: [ Frontend ]
          - name: instance-state-name
            values: [ running ]
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        target_label: __address__
        replacement: '$${1}:3000'
      - source_labels: [__meta_ec2_tag_Name, __meta_ec2_private_ip]
        regex: "(.*);(.*)"
        target_label: instance
        replacement: "$${1} ($${2})"
      - target_label: env
        replacement: 'prod'
      - target_label: service
        replacement: 'nodejs'
      - source_labels: [ __meta_ec2_tag_Name ]
        target_label: instance_name

  # V2 AI 서버 EC2 오토스케일링 그룹 메트릭 수집 (포트 8000)
  - job_name: 'ai-service'
    ec2_sd_configs:
      - region: 'ap-northeast-2'
        port: 8000
        filters:
          - name: tag:Project
            values: [ devths ]
          - name: tag:Service
            values: [ Ai ]
          - name: tag:Version
            values: [ v2 ]
          - name: tag:Environment
            values: [ prod, production ]
          - name: instance-state-name
            values: [ running ]
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        target_label: __address__
        replacement: '$${1}:8000'
      - source_labels: [ __meta_ec2_tag_Name, __meta_ec2_private_ip ]
        regex: '(.*);(.*)'
        target_label: instance
        replacement: '$${1} ($${2})'
      - target_label: env
        replacement: prod

  # VectorDB (ChromaDB) EC2 인스턴스 모니터링 (태그 기반 동적 탐색)
  - job_name: 'vectordb-ec2'
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
    relabel_configs:
      - source_labels: [ __meta_ec2_private_ip ]
        separator: ;
        target_label: __address__
        replacement: $${1}:9100
        action: replace
      - source_labels: [ __meta_ec2_tag_Name, __meta_ec2_private_ip ]
        separator: ;
        regex: (.*);(.*)
        target_label: instance
        replacement: $${1} ($${2})
        action: replace
      - separator: ;
        target_label: env
        replacement: prod
        action: replace
      - separator: ;
        target_label: service
        replacement: vectordb
        action: replace
      - source_labels: [ __meta_ec2_tag_Name ]
        separator: ;
        target_label: instance_name
        replacement: $1
        action: replace
    ec2_sd_configs:
      - endpoint: ""
        region: ap-northeast-2
        refresh_interval: 1m
        port: 9100
        filters:
          - name: tag:Project
            values:
              - devths
          - name: tag:Name
            values:
              - devths-v2-prod-ai-vectorDB
              - devths-v2-production-ai-vectorDB
          - name: tag:Environment
            values:
              - prod
              - production
          - name: instance-state-name
            values:
              - running
        follow_redirects: true
        enable_http2: true

%{ endif ~}

%{ endif ~}
