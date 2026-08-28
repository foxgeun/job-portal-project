#!/bin/bash
set -e

ECR_REGISTRY="${1:-$ECR_REGISTRY}"
ECR_REPO="${2:-$ECR_REPOSITORY}"
ECR_PASSWORD="${3:-$ECR_PASSWORD}"
IMAGE_TAG="${4:-$IMAGE_TAG}"
DB_HOST="${5:-$DB_HOST}"
DB_NAME="${6:-$DB_NAME}"
DB_USERNAME="${7:-$DB_USERNAME}"
DB_PASSWORD="${8:-$DB_PASSWORD}"

echo "=== Starting Blue-Green Deployment ==="

# Docker ECR Login
if [ -n "$ECR_PASSWORD" ] && [ -n "$ECR_REGISTRY" ]; then
    echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$ECR_REGISTRY" || true
fi

# Determine Blue/Green Port
if docker ps --filter "name=app-blue" --filter "status=running" -q | grep -q .; then
    NEW_PORT=8081
    NEW_CONTAINER="app-green"
    OLD_CONTAINER="app-blue"
else
    NEW_PORT=8080
    NEW_CONTAINER="app-blue"
    OLD_CONTAINER="app-green"
fi

FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
echo "Deploying container $NEW_CONTAINER on port $NEW_PORT with image $FULL_IMAGE..."

docker pull "$FULL_IMAGE"

# Clean existing target container & occupied port
docker rm -f "$NEW_CONTAINER" 2>/dev/null || true
for pid in $(docker ps --filter "publish=$NEW_PORT" -q); do
    docker rm -f "$pid" 2>/dev/null || true
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
