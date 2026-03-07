#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.local/env.local"

if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

IMAGE_NAME="${IMAGE_NAME:-chronicleglados/aphelion}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
GCP_PROJECT="${GCP_PROJECT_ID:?GCP_PROJECT_ID is required}"
GCP_REGION="${GCP_REGION:-us-central1}"
CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-aphelion}"

BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ]; then
  echo "FAIL: deploy only allowed from main (currently on $BRANCH)"
  exit 1
fi

echo "==> Deploying to Cloud Run"
echo "    Project:  $GCP_PROJECT"
echo "    Region:   $GCP_REGION"
echo "    Service:  $CLOUD_RUN_SERVICE"
echo "    Image:    docker.io/$IMAGE_NAME:$IMAGE_TAG"

gcloud run deploy "$CLOUD_RUN_SERVICE" \
  --project "$GCP_PROJECT" \
  --region "$GCP_REGION" \
  --image "docker.io/$IMAGE_NAME:$IMAGE_TAG" \
  --platform managed \
  --port 8080 \
  --allow-unauthenticated \
  --quiet

SERVICE_URL=$(gcloud run services describe "$CLOUD_RUN_SERVICE" \
  --project "$GCP_PROJECT" \
  --region "$GCP_REGION" \
  --format "value(status.url)")

echo "==> Deployed: $SERVICE_URL"

echo "==> Verifying deployment"
STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$SERVICE_URL")
if [ "$STATUS" != "200" ]; then
  echo "WARN: expected 200, got $STATUS (service may still be starting)"
else
  echo "PASS (HTTP $STATUS)"
fi
