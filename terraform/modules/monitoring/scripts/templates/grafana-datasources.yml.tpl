apiVersion: 1

datasources:
  # Prometheus - 메트릭 수집 (EC2 로컬)
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "15s"
      queryTimeout: "60s"
      httpMethod: POST

  # Loki - 로그 수집
  # k8s_loki_url이 설정되면 in-cluster NodePort, 아니면 EC2 로컬
  - name: Loki
    type: loki
    access: proxy
%{ if k8s_loki_url != "" ~}
    url: ${k8s_loki_url}
%{ else ~}
    url: http://loki:3100
%{ endif ~}
    isDefault: false
    editable: true
    jsonData:
      derivedFields:
        - datasourceUid: tempo
          name: TraceID
          matcherRegex: '"traceId":"([^"]+)"'
          url: '$${__value.raw}'

        - datasourceUid: tempo
          name: SpanID
          matcherRegex: '"spanId":"([^"]+)"'
          url: '$${__value.raw}'

  # Tempo - 분산 추적
  # k8s_tempo_url이 설정되면 in-cluster NodePort, 아니면 EC2 로컬
  - name: Tempo
    type: tempo
    uid: tempo
    access: proxy
%{ if k8s_tempo_url != "" ~}
    url: ${k8s_tempo_url}
%{ else ~}
    url: http://tempo:3200
%{ endif ~}
    editable: true
    jsonData:
      tracesToLogsV2:
        datasourceUid: Loki
        spanStartTimeShift: "-1h"
        spanEndTimeShift: "1h"
        filterByTraceID: true
        filterBySpanID: false
      tracesToMetrics:
        datasourceUid: Prometheus
        spanStartTimeShift: "-1h"
        spanEndTimeShift: "1h"
      nodeGraph:
        enabled: true
      search:
        hide: false
      serviceMap:
        datasourceUid: Prometheus
