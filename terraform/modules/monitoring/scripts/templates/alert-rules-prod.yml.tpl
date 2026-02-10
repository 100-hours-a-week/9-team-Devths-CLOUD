groups:
  - name: production_infrastructure_health
    interval: 30s
    rules:
      # 1. 서버 생존 확인 (가장 높은 우선순위)
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          environment: production
        annotations:
          summary: "🚨 [운영] 서버 다운 발생: {{ $labels.instance }}"
          description: "운영 서버가 1분 이상 응답하지 않습니다. 즉시 확인이 필요합니다."

      # 2. CPU 사용량 - Warning (75%)
      - alert: HighCpuUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 75
        for: 3m
        labels:
          severity: warning
          environment: production
        annotations:
          summary: "⚠️ [운영] CPU 사용량 높음"
          description: "운영 서버 CPU 사용량이 3분간 75%를 초과했습니다. (현재: {{ $value | humanize }}%)"

      # 3. CPU 사용량 - Critical (90%)
      - alert: CriticalCpuUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 2m
        labels:
          severity: critical
          environment: production
        annotations:
          summary: "🔥 [운영] CPU 과부하 심각"
          description: "운영 서버 CPU 사용량이 90%를 넘었습니다. 서비스 지연이 발생할 수 있습니다."

      # 4. 메모리 사용량 (85%)
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          environment: production
        annotations:
          summary: "⚠️ [운영] 메모리 부족 위험"
          description: "메모리 사용량이 85%를 초과했습니다. Swap 발생 여부를 확인하세요."

      # 5. 디스크 공간 (90%) - 운영에선 이게 터지면 정말 답이 없습니다.
      - alert: HighDiskUsage
        expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100 > 90
        for: 5m
        labels:
          severity: critical
          environment: production
        annotations:
          summary: "💾 [운영] 디스크 용량 임박 (90%↑)"
          description: "루트 디스크 잔여 용량이 10% 미만입니다. 로그 및 임시 파일을 점검하세요."