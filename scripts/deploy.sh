#!/bin/bash
set -e

ECR_REGISTRY="$1"
ECR_REPO="$2"
ECR_PASSWORD="$3"
IMAGE_TAG="$4"
if [ -z "$IMAGE_TAG" ]; then
    IMAGE_TAG="latest"
fi
DB_HOST="$5"
DB_NAME="$6"
DB_USERNAME="$7"
DB_PASSWORD="$8"

echo "=== Starting Blue-Green Deployment ==="
if [ -n "$ECR_PASSWORD" ] && [ -n "$ECR_REGISTRY" ]; then
    echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$ECR_REGISTRY" || true
fi

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
echo "Deploying $NEW_CONTAINER on port $NEW_PORT with image $FULL_IMAGE..."
docker pull "$FULL_IMAGE"

docker rm -f "$NEW_CONTAINER" 2>/dev/null || true
for pid in $(docker ps --filter "publish=$NEW_PORT" -q); do
    docker rm -f "$pid" 2>/dev/null || true
done

docker run -d \
  --name "$NEW_CONTAINER" \
  --restart unless-stopped \
  -p "$NEW_PORT:8080" \
  -e DB_HOST="$DB_HOST" \
  -e DB_NAME="$DB_NAME" \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  "$FULL_IMAGE"

echo "Waiting 20s for Spring Boot startup..."
sleep 20

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$NEW_PORT/actuator/health" 2>/dev/null || echo "000")
echo "Health check status on port $NEW_PORT: $STATUS"

if [ "$STATUS" = "200" ]; then
  if docker ps -a --format '{{.Names}}' | grep -q "^${OLD_CONTAINER}$"; then
    docker stop "$OLD_CONTAINER" 2>/dev/null || true
    docker rm "$OLD_CONTAINER" 2>/dev/null || true
  fi
  echo "🚀 Deployment Succeeded!"
  exit 0
else
  echo "❌ Health check failed with status $STATUS"
  docker rm -f "$NEW_CONTAINER" 2>/dev/null || true
  exit 1
fi
