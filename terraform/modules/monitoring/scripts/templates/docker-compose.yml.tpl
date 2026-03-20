%{ if environment == "nonprod" ~}
services:
  # 프로메테우스 설정
  prometheus:
    image: prom/prometheus:latest
    container_name: devths-prometheus
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-remote-write-receiver'
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts:/etc/prometheus/alerts:ro
      - prometheus-data:/prometheus
    networks:
      - monitoring
    extra_hosts:
      - "host.docker.internal:host-gateway"

  # 알림매니저
  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager-nonprod
    environment:
      - DISCORD_WEBHOOK_NONPROD=$${DISCORD_WEBHOOK_NONPROD}
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    ports:
      - "9093:9093"
    networks:
      - monitoring
    depends_on:
      - prometheus

  # 그라파나
  grafana:
    image: grafana/grafana:latest
    container_name: devths-grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=$${GF_USER}
      - GF_SECURITY_ADMIN_PASSWORD=$${GF_PASSWORD}
      - GF_SERVER_ROOT_URL=$${GF_URL}
      - GF_SERVER_DOMAIN=$${GF_DOMAIN}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards:ro
    networks:
      - monitoring
    depends_on:
      - prometheus

%{ if k8s_tempo_url == "" ~}
  # 그라파나 Tempo (EC2 로컬 실행 — k8s_tempo_nodeport_url 미설정 시)
  tempo:
    image: grafana/tempo:2.6.1
    container_name: devths-tempo
    restart: unless-stopped
    environment:
      - AWS_REGION=$${AWS_REGION}
      - TEMPO_S3_BUCKET=$${TEMPO_S3_BUCKET}
    ports:
      - "3200:3200"
      - "4318:4318"
      - "4317:4317"
    volumes:
      - ./tempo/tempo-config.yml:/etc/tempo.yml:ro
      - tempo-data:/var/tempo
    command: [ "-config.file=/etc/tempo.yml" ]
    networks:
      - monitoring

%{ endif ~}
%{ if k8s_loki_url == "" ~}
  # Loki (EC2 로컬 실행 — k8s_loki_nodeport_url 미설정 시)
  loki:
    image: grafana/loki:latest
    container_name: devths-loki
    restart: unless-stopped
    environment:
      - AWS_REGION=$${AWS_REGION}
      - LOKI_S3_BUCKET=$${LOKI_S3_BUCKET}
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - monitoring

  # Promtail (EC2 로컬 Loki 사용 시만 포함)
  promtail:
    image: grafana/promtail:latest
    container_name: devths-promtail
    restart: unless-stopped
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/log:/var/log:ro
      - ./promtail/config.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring
    depends_on:
      - loki

%{ endif ~}
volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
%{ if k8s_loki_url == "" ~}
  loki-data:
    driver: local
%{ endif ~}
%{ if k8s_tempo_url == "" ~}
  tempo-data:
    driver: local
%{ endif ~}

networks:
  monitoring:
    driver: bridge

%{ else ~}
services:
  # 프로메테우스 설정
  prometheus:
    image: prom/prometheus:latest
    container_name: devths-prometheus-prod
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=90d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-remote-write-receiver'
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts:/etc/prometheus/alerts:ro
      - prometheus-data:/prometheus
    networks:
      - monitoring
    extra_hosts:
      - "host.docker.internal:host-gateway"

  # 알림매니저
  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager-prod
    environment:
      - DISCORD_WEBHOOK_PROD=$${DISCORD_WEBHOOK_PROD}
      - DISCORD_PROD_MENTION=$${DISCORD_PROD_MENTION}
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    ports:
      - "9093:9093"
    networks:
      - monitoring
    depends_on:
      - prometheus

  # 그라파나
  grafana:
    image: grafana/grafana:latest
    container_name: devths-grafana-prod
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=$${GF_USER}
      - GF_SECURITY_ADMIN_PASSWORD=$${GF_PASSWORD}
      - GF_SERVER_ROOT_URL=$${GF_URL}
      - GF_SERVER_DOMAIN=$${GF_DOMAIN}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards:ro
    networks:
      - monitoring
    depends_on:
      - prometheus

%{ if k8s_tempo_url == "" ~}
  # 그라파나 Tempo (EC2 로컬 실행 — k8s_tempo_nodeport_url 미설정 시)
  tempo:
    image: grafana/tempo:2.6.1
    container_name: devths-tempo-prod
    restart: unless-stopped
    environment:
      - AWS_REGION=$${AWS_REGION}
      - TEMPO_S3_BUCKET=$${TEMPO_S3_BUCKET}
    ports:
      - "3200:3200"
      - "4318:4318"
      - "4317:4317"
    volumes:
      - ./tempo/tempo-config.yml:/etc/tempo.yml:ro
      - tempo-data:/var/tempo
    command: [ "-config.file=/etc/tempo.yml" ]
    networks:
      - monitoring

%{ endif ~}
%{ if k8s_loki_url == "" ~}
  # Loki (EC2 로컬 실행 — k8s_loki_nodeport_url 미설정 시)
  loki:
    image: grafana/loki:latest
    container_name: devths-loki-prod
    restart: unless-stopped
    environment:
      - AWS_REGION=$${AWS_REGION}
      - LOKI_S3_BUCKET=$${LOKI_S3_BUCKET}
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - monitoring

  # Promtail (EC2 로컬 Loki 사용 시만 포함)
  promtail:
    image: grafana/promtail:latest
    container_name: devths-promtail-prod
    restart: unless-stopped
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/log:/var/log:ro
      - ./promtail/config.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring
    depends_on:
      - loki

%{ endif ~}
volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
%{ if k8s_loki_url == "" ~}
  loki-data:
    driver: local
%{ endif ~}
%{ if k8s_tempo_url == "" ~}
  tempo-data:
    driver: local
%{ endif ~}

networks:
  monitoring:
    driver: bridge

%{ endif ~}
