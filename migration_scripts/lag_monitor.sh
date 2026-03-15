#!/bin/bash
# lag_monitor.sh

LOG_FILE="/tmp/replication_lag_$(date +%Y%m%d).log"
ALERT_THRESHOLD=1048576  # 1MB

echo "Replication Lag 모니터링 시작: $(date)" | tee -a $LOG_FILE

while true; do
    LAG=$(sudo -u postgres psql -t -A -d devths -c "
        SELECT pg_wal_lsn_diff(
            pg_current_wal_lsn(), replay_lsn
        )
        FROM pg_stat_replication
        WHERE application_name = 'devths_sub';
    " 2>/dev/null)

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if [ -z "$LAG" ]; then
        echo "$TIMESTAMP ⚠ 복제 연결 없음 - Subscriber(RDS) 구독 확인 필요" | tee -a $LOG_FILE
    elif [ "$LAG" -eq 0 ]; then
        echo "$TIMESTAMP ✅ Lag: 0 bytes (동기화 완료)" | tee -a $LOG_FILE
    elif [ "$LAG" -gt "$ALERT_THRESHOLD" ]; then
        echo "$TIMESTAMP 🚨 Lag 경고: ${LAG} bytes (1MB 초과)" | tee -a $LOG_FILE
    else
        echo "$TIMESTAMP ℹ Lag: ${LAG} bytes" | tee -a $LOG_FILE
    fi

    sleep 5
done
