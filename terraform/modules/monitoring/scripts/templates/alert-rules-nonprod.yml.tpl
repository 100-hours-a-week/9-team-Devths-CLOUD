groups:
  - name: infrastructure_health
    interval: 30s
    rules:

      # 1. CPU 사용량 (80% 이상)
      - alert: HighCpuUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 70
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "CPU 과부하: {{ $labels.instance }}"
          description: "CPU 사용량이 3분간 70%를 초과했습니다. (현재: {{ $value | humanize }}%)"

      # 2. 메모리 사용량 (85% 이상)
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "메모리 부족: {{ $labels.instance }}"
          description: "메모리 사용량이 85%를 초과했습니다. (현재: {{ $value | humanize }}%)"

      # 3. 디스크 공간 (90% 이상) - 이거 꼭 필요합니다!
      - alert: HighDiskUsage
        expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100 > 90
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "디스크 풀(Full) 임박: {{ $labels.instance }}"
          description: "루트 경로(/) 디스크 사용량이 90%를 초과했습니다. 로그 정리가 필요할 수 있습니다."