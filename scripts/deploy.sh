#!/bin/bash
# =============================================================
# 무중단 배포 스크립트 (Blue-Green 포트 스위치 방식)
# 현재 활성 포트를 확인하고, 반대 포트에 새 컨테이너를 기동합니다.
# =============================================================
set -e

ECR_REGISTRY="${ECR_REGISTRY}"
ECR_REPOSITORY="${ECR_REPOSITORY:-job-portal}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

BLUE_PORT=8080
GREEN_PORT=8081
HEALTH_CHECK_RETRIES=12
HEALTH_CHECK_INTERVAL=10

# ── 현재 활성 포트/컨테이너 판별 ──────────────────────────────
CURRENT_PORT=$(docker ps --filter "name=app-blue" --filter "status=running" -q | wc -l)
if [ "$CURRENT_PORT" -gt 0 ]; then
    ACTIVE_PORT=$BLUE_PORT
    ACTIVE_CONTAINER="app-blue"
    NEW_PORT=$GREEN_PORT
    NEW_CONTAINER="app-green"
else
    ACTIVE_PORT=$GREEN_PORT
    ACTIVE_CONTAINER="app-green"
    NEW_PORT=$BLUE_PORT
    NEW_CONTAINER="app-blue"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 현재 활성: ${ACTIVE_CONTAINER}(${ACTIVE_PORT}) → 신규 배포: ${NEW_CONTAINER}(${NEW_PORT})"

# ── 새 이미지 Pull ────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Docker 이미지 Pull: ${FULL_IMAGE}"
docker pull "${FULL_IMAGE}"

# ── 신규 컨테이너 실행 ────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${NEW_CONTAINER} 컨테이너 시작 (포트: ${NEW_PORT})"

# 이전 같은 이름의 컨테이너가 있으면 제거
docker rm -f "${NEW_CONTAINER}" 2>/dev/null || true

docker run -d \
    --name "${NEW_CONTAINER}" \
    --restart unless-stopped \
    -p "${NEW_PORT}:8080" \
    -e DB_HOST="${DB_HOST}" \
    -e DB_NAME="${DB_NAME}" \
    -e DB_USERNAME="${DB_USERNAME}" \
    -e DB_PASSWORD="${DB_PASSWORD}" \
    -e SARAMIN_API_KEY="${SARAMIN_API_KEY}" \
    "${FULL_IMAGE}"

# ── 헬스체크 ─────────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 헬스체크 시작 (최대 ${HEALTH_CHECK_RETRIES}회 / ${HEALTH_CHECK_INTERVAL}초 간격)"
HEALTHY=false
for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${NEW_PORT}/actuator/health" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 헬스체크 성공 (시도 ${i}/${HEALTH_CHECK_RETRIES})"
        HEALTHY=true
        break
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ 대기 중... (${i}/${HEALTH_CHECK_RETRIES}) HTTP Status: ${STATUS}"
    sleep $HEALTH_CHECK_INTERVAL
done

if [ "$HEALTHY" != "true" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 헬스체크 실패! ${NEW_CONTAINER} 컨테이너를 중단합니다."
    docker rm -f "${NEW_CONTAINER}" 2>/dev/null || true
    exit 1
fi

# ── 기존 컨테이너 종료 ────────────────────────────────────────
if [ -n "$(docker ps --filter "name=${ACTIVE_CONTAINER}" -q 2>/dev/null)" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 기존 컨테이너 종료: ${ACTIVE_CONTAINER}"
    docker stop "${ACTIVE_CONTAINER}" || true
    docker rm "${ACTIVE_CONTAINER}" || true
fi

# ── 사용하지 않는 이미지 정리 ─────────────────────────────────
docker image prune -f --filter "until=24h" 2>/dev/null || true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 배포 완료! 활성 컨테이너: ${NEW_CONTAINER} (포트: ${NEW_PORT})"
