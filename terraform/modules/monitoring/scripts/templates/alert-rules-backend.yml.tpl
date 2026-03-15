%{ if environment == "nonprod" ~}
groups:
  - name: backend_monitoring
    interval: 30s
    rules:
      # 1. 백엔드 API 500 에러 감지 (인스턴스별 에러율 5% 초과 시) - NoData 방지
      - alert: BackendApiErrorHigh
        expr: |
          (
            sum by (instance) (rate(http_server_requests_seconds_count{status=~"5.."}[3m]))
            /
            sum by (instance) (rate(http_server_requests_seconds_count[3m]))
          ) > 0.05
          and
          sum by (instance) (rate(http_server_requests_seconds_count[3m])) > 0
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "API 에러 급증: {{ $labels.instance }}"
          description: "최근 3분간 {{ $labels.instance }} 서버의 500번대 에러율이 5%를 초과했습니다. (현재: {{ $value | humanizePercentage }})"

      # 2. 레이트 리미트 (429 비율 5% 초과) - NoData 방지
      - alert: RateLimit
        expr: |
          (
            sum by (instance) (rate(http_server_requests_seconds_count{status="429"}[3m]))
            /
            sum by (instance) (rate(http_server_requests_seconds_count[3m]))
          ) > 0.05
          and
          sum by (instance) (rate(http_server_requests_seconds_count[3m])) > 0
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "인스턴스 {{ $labels.instance }} 429 에러 비율 높음"
          description: "429 에러 비율이 5%를 초과했습니다. (현재값: {{ $value | printf \"%.2f\" }})"

      # 3. JVM 힙 메모리 사용량 (85% 초과 시)
      # - 보통 JVM 메트릭이 있는 인스턴스에서만 나오므로 NoData 문제는 덜하지만,
      #   scrape 끊김/인스턴스 종료 시 NoData를 피하려면 아래 'and ... > 0' 가드를 추가
      - alert: SpringBootJvmHeapUsageHigh
        expr: |
          (
            sum by (instance) (jvm_memory_used_bytes{area="heap"})
            /
            sum by (instance) (jvm_memory_max_bytes{area="heap"})
          ) > 0.85
          and
          sum by (instance) (jvm_memory_max_bytes{area="heap"}) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "JVM 힙 메모리 부족: {{ $labels.instance }}"
          description: "Spring Boot 힙 메모리 사용량이 85%를 초과했습니다. OOM 발생 위험이 높으니 덤프 확인이 필요합니다."

      # 4. DB 커넥션 풀 고갈 (70% 초과 시) - NoData 방지
      - alert: HikariPoolConnectionsFull
        expr: |
          (
            sum by (instance, pool) (hikaricp_connections_active)
            /
            sum by (instance, pool) (hikaricp_connections_max)
          ) > 0.7
          and
          sum by (instance, pool) (hikaricp_connections_max) > 0
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "DB 커넥션 고갈 위기: {{ $labels.instance }}"
          description: "활성 DB 커넥션이 70%를 초과했습니다. DB 부하 혹은 커넥션 누수를 점검하세요."

      # 5. API 응답 지연 (평균 응답속도 3초 초과 시) - NoData 방지
      - alert: BackendApiSlowResponse
        expr: |
          (
            sum by (instance) (rate(http_server_requests_seconds_sum[3m]))
            /
            sum by (instance) (rate(http_server_requests_seconds_count[3m]))
          ) > 3
          and
          sum by (instance) (rate(http_server_requests_seconds_count[3m])) > 0
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "API 응답 지연: {{ $labels.instance }}"
          description: "최근 3분간 API 평균 응답 시간이 3초를 초과했습니다. (현재: {{ $value | humanizeDuration }})"

#      # 6. 앱 재시작 감지 (최근 15분 내 프로세스 시작 시간 변경 시)
#      - alert: BackendAppRestarted
#        expr: changes(process_start_time_seconds[15m]) > 0
#        for: 1m
#        labels:
#          severity: warning
#        annotations:
#          summary: "앱 재시작됨: {{ $labels.instance }}"
#          description: "최근 15분 이내에 {{ $labels.instance }} 프로세스가 다시 시작되었습니다."
%{ else ~}
groups:
  - name: backend_monitoring
    interval: 30s
    rules:
      # 1. 백엔드 API 500 에러 감지 (인스턴스별 에러율 3% 초과 시) - NoData 방지
      - alert: BackendApiErrorHigh
        expr: |
          (
            sum by (instance) (rate(http_server_requests_seconds_count{status=~"5.."}[3m]))
            /
            sum by (instance) (rate(http_server_requests_seconds_count[3m]))
          ) > 0.03
          and
          sum by (instance) (rate(http_server_requests_seconds_count[3m])) > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "[PROD] API 에러 급증: {{ $labels.instance }}"
          description: "[운영환경] 최근 3분간 {{ $labels.instance }} 서버의 500번대 에러율이 3%를 초과했습니다. (현재: {{ $value | humanizePercentage }})"

      # 2. 레이트 리미트 (429 비율 3% 초과) - NoData 방지
      - alert: RateLimit
        expr: |
          (
            sum by (instance) (rate(http_server_requests_seconds_count{status="429"}[3m]))
            /
            sum by (instance) (rate(http_server_requests_seconds_count[3m]))
          ) > 0.03
          and
          sum by (instance) (rate(http_server_requests_seconds_count[3m])) > 0
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "인스턴스 {{ $labels.instance }} 429 에러 비율 높음"
          description: "429 에러 비율이 5%를 초과했습니다. (현재값: {{ $value | printf \"%.2f\" }})"

      # 3. JVM 힙 메모리 사용량 (80% 초과 시)
      # - 보통 JVM 메트릭이 있는 인스턴스에서만 나오므로 NoData 문제는 덜하지만,
      #   scrape 끊김/인스턴스 종료 시 NoData를 피하려면 아래 'and ... > 0' 가드를 추가
      - alert: SpringBootJvmHeapUsageHigh
        expr: |
          (
            sum by (instance) (jvm_memory_used_bytes{area="heap"})
            /
            sum by (instance) (jvm_memory_max_bytes{area="heap"})
          ) > 0.80
          and
          sum by (instance) (jvm_memory_max_bytes{area="heap"}) > 0
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "[PROD] JVM 힙 메모리 부족: {{ $labels.instance }}"
          description: "[운영환경] Spring Boot 힙 메모리 사용량이 80%를 초과했습니다. OOM 발생 위험이 높으니 덤프 확인이 필요합니다."

      # 4. DB 커넥션 풀 고갈 (60% 초과 시) - NoData 방지
      - alert: HikariPoolConnectionsFull
        expr: |
          (
            sum by (instance, pool) (hikaricp_connections_active)
            /
            sum by (instance, pool) (hikaricp_connections_max)
          ) > 0.60
          and
          sum by (instance, pool) (hikaricp_connections_max) > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "[PROD] DB 커넥션 고갈 위기: {{ $labels.instance }}"
          description: "[운영환경] 활성 DB 커넥션이 60%를 초과했습니다. DB 부하 혹은 커넥션 누수를 점검하세요."

      # 5. API 응답 지연 (평균 응답속도 3초 초과 시) - NoData 방지
      - alert: BackendApiSlowResponse
        expr: |
          (
            sum by (instance) (rate(http_server_requests_seconds_sum[3m]))
            /
            sum by (instance) (rate(http_server_requests_seconds_count[3m]))
          ) > 3
          and
          sum by (instance) (rate(http_server_requests_seconds_count[3m])) > 0
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "API 응답 지연: {{ $labels.instance }}"
          description: "최근 3분간 API 평균 응답 시간이 3초를 초과했습니다. (현재: {{ $value | humanizeDuration }})"

      # 6. 앱 재시작 감지 (최근 15분 내 프로세스 시작 시간 변경 시)
      - alert: BackendAppRestarted
        expr: changes(process_start_time_seconds[15m]) > 0
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "앱 재시작됨: {{ $labels.instance }}"
          description: "최근 15분 이내에 {{ $labels.instance }} 프로세스가 다시 시작되었습니다."
%{ endif ~}
