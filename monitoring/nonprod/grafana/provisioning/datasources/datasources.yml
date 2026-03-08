apiVersion: 1

datasources:
  # Prometheus - 메트릭 수집
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
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: false
    editable: true
    jsonData:
      derivedFields:
        - datasourceUid: tempo
          name: TraceID
          # 작은따옴표(' ')로 감싸면 백슬래시 하나만 써도 됩니다.
          matcherRegex: '\[([a-f0-9]+),'
          url: '$${__value.raw}'

        - datasourceUid: tempo
          name: SpanID
          # 여기도 마찬가지로 작은따옴표 사용
          matcherRegex: ',([a-f0-9]+)\]'
          url: '$${__value.raw}'

  # Tempo - 분산 추적
  - name: Tempo
    type: tempo
    uid: tempo
    access: proxy
    url: http://tempo:3200
    editable: true
    jsonData:
      # Loki와 연결하여 트레이스에서 로그로 이동 가능
      tracesToLogsV2:
        datasourceUid: Loki
        spanStartTimeShift: "-1h"
        spanEndTimeShift: "1h"
        filterByTraceID: true
        filterBySpanID: false
        tags:
          - key: application
            value: devths-be
      # Prometheus와 연결하여 트레이스에서 메트릭으로 이동 가능
      tracesToMetrics:
        datasourceUid: Prometheus
        spanStartTimeShift: "-1h"
        spanEndTimeShift: "1h"
        tags:
          - key: application
            value: devths-be
      nodeGraph:
        enabled: true
      search:
        hide: false
      serviceMap:
        datasourceUid: prometheus