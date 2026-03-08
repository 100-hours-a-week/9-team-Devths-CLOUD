%{ if environment == "nonprod" ~}
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'instance', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  # nonprod 환경 전용 수신처
  receiver: 'discord-nonprod'

receivers:
  # 비운영 환경 수신처 (nonprod 스택 전용)
  - name: 'discord-nonprod'
    discord_configs:
      - webhook_url: '$${DISCORD_WEBHOOK_NONPROD}'
        send_resolved: true
        username: 'Prometheus-NonProd-Bot'
        title: "[{{ .Status | toUpper }}] 비운영(NON-PROD) 인프라 알람"
        message: >-
          {{ if eq .Status "firing" }}⚠️ **비운영 환경 확인 필요**{{ end }}
          **알람명:** {{ .GroupLabels.alertname }}
          **환경:** {{ .CommonLabels.env }}
          **상세 내역:**
          {{ range .Alerts }}- 대상: {{ .Labels.instance }}
            - 내용: {{ .Annotations.description }}
          {{ end }}

%{ else ~}
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'instance', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  # prod 환경 전용 수신처
  receiver: 'discord-prod'

receivers:
  # 운영 환경 수신처 (prod 스택 전용)
  - name: 'discord-prod'
    discord_configs:
      - webhook_url: '$${DISCORD_WEBHOOK_PROD}'
        send_resolved: true
        username: 'Prometheus-Prod-Bot'
        title: "🚨 [{{ .Status | toUpper }}] 운영(PROD) 장애 알람"
        message: >-
          {{ if eq .Status "firing" }}🔥 $${DISCORD_PROD_MENTION} **운영 서버 장애 발생!**{{ end }}
          **알람명:** {{ .GroupLabels.alertname }}
          **환경:** PROD
          **상세 내역:**
          {{ range .Alerts }}- 대상: {{ .Labels.instance }}
            - 내용: {{ .Annotations.description }}
          {{ end }}

%{ endif ~}
