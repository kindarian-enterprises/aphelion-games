#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.local/env.local"
CONTAINER_NAME="aphelion-ci-test"

if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

IMAGE_NAME="${IMAGE_NAME:-chronicleglados/aphelion}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

cleanup() {
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Building static site"
make -C "$PROJECT_DIR" build

echo "==> Building container"
docker build -t "$IMAGE_NAME:$IMAGE_TAG" "$PROJECT_DIR"

echo "==> Starting container"
cleanup
docker run -d --name "$CONTAINER_NAME" -p 8080:8080 "$IMAGE_NAME:$IMAGE_TAG"
sleep 2

echo "==> Smoke test"
STATUS=$(curl -o /dev/null -s -w "%{http_code}" http://localhost:8080)
if [ "$STATUS" != "200" ]; then
  echo "FAIL: expected 200, got $STATUS"
  docker logs "$CONTAINER_NAME"
  exit 1
fi
echo "PASS (HTTP $STATUS)"

if [ "${1:-}" = "--push" ]; then
  BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD)
  if [ "$BRANCH" != "main" ]; then
    echo "FAIL: publish only allowed from main (currently on $BRANCH)"
    exit 1
  fi
  SHA_TAG=$(git -C "$PROJECT_DIR" rev-parse HEAD)
  echo "==> Pushing to DockerHub"
  echo "$DOCKER_HUB_ACCESS_TOKEN" | docker login -u "$DOCKER_HUB_USER" --password-stdin
  docker tag "$IMAGE_NAME:$IMAGE_TAG" "$IMAGE_NAME:$SHA_TAG"
  docker push "$IMAGE_NAME:$IMAGE_TAG"
  docker push "$IMAGE_NAME:$SHA_TAG"
  echo "Pushed $IMAGE_NAME:$IMAGE_TAG and $IMAGE_NAME:$SHA_TAG"
fi
