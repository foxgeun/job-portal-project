#!/bin/bash
# =============================================================
# 헬스체크 스크립트
# 사용법: ./health-check.sh [PORT]
# =============================================================

PORT="${1:-8080}"
MAX_RETRIES=12
INTERVAL=10
HEALTH_URL="http://localhost:${PORT}/actuator/health"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 헬스체크 시작 - URL: ${HEALTH_URL}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 최대 ${MAX_RETRIES}회 시도 / ${INTERVAL}초 간격"

for i in $(seq 1 $MAX_RETRIES); do
    HTTP_STATUS=$(curl -s -o /tmp/health_response.json -w "%{http_code}" "${HEALTH_URL}" 2>/dev/null || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        STATUS=$(cat /tmp/health_response.json 2>/dev/null | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ "$STATUS" = "UP" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 서비스 정상 (시도 ${i}/${MAX_RETRIES})"
            exit 0
        fi
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ 대기 중 (${i}/${MAX_RETRIES}) - HTTP: ${HTTP_STATUS}"
    
    if [ "$i" -lt "$MAX_RETRIES" ]; then
        sleep $INTERVAL
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 헬스체크 실패: 최대 재시도 횟수 초과"
exit 1
