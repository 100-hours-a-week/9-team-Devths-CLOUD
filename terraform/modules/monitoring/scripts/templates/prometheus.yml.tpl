global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'devths-${environment}'
    region: '${aws_region}'

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
  # Dev Environment - Node Exporter (EC2 Service Discovery)
  - job_name: 'node-exporter-dev'
    ec2_sd_configs:
      - region: '${aws_region}'
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
      # Use private IP
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'
      # Add environment label
      - target_label: env
        replacement: 'dev'
      # Add service label
      - target_label: service
        replacement: 'node-exporter'
      # Add instance name from Name tag
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      # Add instance type
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      # Add availability zone
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # Staging Environment - Node Exporter (EC2 Service Discovery)
  - job_name: 'node-exporter-staging'
    ec2_sd_configs:
      - region: '${aws_region}'
        port: 9100
        filters:
          - name: tag:Project
            values: [devths]
          - name: tag:Environment
            values: [staging]
          - name: tag:Version
            values: [v2]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      # Use private IP
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'
      # Add environment label
      - target_label: env
        replacement: 'staging'
      # Add service label
      - target_label: service
        replacement: 'node-exporter'
      # Add instance name from Name tag
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      # Add instance type
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      # Add availability zone
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep
%{ else ~}
  # Production Environment - Node Exporter (EC2 Service Discovery)
  - job_name: 'node-exporter-prod'
    ec2_sd_configs:
      - region: '${aws_region}'
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
      # Use private IP
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '$${1}:9100'
      # Add environment label
      - target_label: env
        replacement: 'prod'
      # Add service label
      - target_label: service
        replacement: 'node-exporter'
      # Add instance name from Name tag
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      # Add instance type
      - source_labels: [__meta_ec2_instance_type]
        target_label: instance_type
      # Add availability zone
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep
%{ endif ~}
