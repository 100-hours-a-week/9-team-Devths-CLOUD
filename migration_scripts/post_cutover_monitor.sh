#!/bin/bash
# post_cutover_monitor.sh

HEALTH_URL="https://api.devths.com/actuator/health"
LOG_FILE="/tmp/post_cutover_$(date +%Y%m%d).log"
CHECK_INTERVAL=10

echo "컷오버 후 모니터링 시작: $(date)" | tee -a $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

    if [ "$STATUS" != "200" ]; then
        echo "$TIMESTAMP 🚨 헬스체크 실패: HTTP $STATUS → 롤백 트리거 조건 발생!" | tee -a $LOG_FILE
        break
    fi

    echo "$TIMESTAMP ✅ 헬스체크 정상: HTTP $STATUS" | tee -a $LOG_FILE
    sleep $CHECK_INTERVAL
done
