global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'devths-${environment}'
    region: 'ap-northeast-2'

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - '/etc/prometheus/alerts/*.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          env: '${environment}'
          service: 'prometheus'

%{ if environment == "nonprod" ~}
  # Dev Environment - Node Exporter
  - job_name: 'node-exporter-dev'
    static_configs:
      - targets: ['${target_dev_ip}:9100']
        labels:
          env: 'dev'
          service: 'node-exporter'
          instance_name: 'devths-v1-dev'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # Staging Environment - Node Exporter
  - job_name: 'node-exporter-staging'
    static_configs:
      - targets: ['${target_staging_ip}:9100']
        labels:
          env: 'staging'
          service: 'node-exporter'
          instance_name: 'devths-v1-stg'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep
%{ else ~}
  # Production Environment - Node Exporter
  - job_name: 'node-exporter-prod'
    static_configs:
      - targets: ['${target_prod_ip}:9100']
        labels:
          env: 'prod'
          service: 'node-exporter'
          instance_name: 'devths-v1-prod'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep
%{ endif ~}
