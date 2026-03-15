#!/bin/bash
# ==========================================
# Rate Limit 리셋 스크립트 (부하 테스트용)
# 대상: Redis 내의 모든 rate-limit:board:* 키 
# 주기: 1초마다 강제 삭제 (HTTP 429 에러 우회)
# ==========================================

REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"

echo "🔄 RL 강제 리셋 (Bypass) 시작"
echo "   Redis: ${REDIS_HOST}:${REDIS_PORT}"
echo "   대상: rate-limit:board:*"
echo "   주기: 1초"
echo "   Ctrl+C로 종료"
echo "========================================="

while true; do
    # 현재 존재하는 모든 rate-limit 키 검색 후 일괄 삭제
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" KEYS "rate-limit:board:*" | xargs -r redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DEL > /dev/null 2>&1
    
    echo "$(date '+%H:%M:%S') Rate Limit Keys (rate-limit:board:*) 삭제 완료"
    sleep 1
done
