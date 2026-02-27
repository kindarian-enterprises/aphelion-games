#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.local/env.local"

if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

GCP_PROJECT="${GCP_PROJECT_ID:?GCP_PROJECT_ID is required (set in .local/env.local)}"
GCP_REGION="${GCP_REGION:-us-central1}"
CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-aphelion}"
SA_NAME="aphelion-deploy"
SA_EMAIL="$SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com"
POOL_NAME="github-actions"
PROVIDER_NAME="github"
GITHUB_REPO="${GITHUB_REPO:-kindarian-enterprises/aphelion-games}"

if ! command -v gcloud &>/dev/null; then
  echo "FAIL: gcloud is not installed"
  exit 1
fi

echo "==> Checking gcloud auth"
gcloud auth print-access-token --project "$GCP_PROJECT" >/dev/null 2>&1 \
  || { echo "FAIL: not authenticated — run 'gcloud auth login'"; exit 1; }

GCP_PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT" --format="value(projectNumber)")

# --- Service Account ---------------------------------------------------------

echo "==> Creating service account: $SA_NAME"
if gcloud iam service-accounts describe "$SA_EMAIL" --project "$GCP_PROJECT" &>/dev/null; then
  echo "    Already exists, skipping creation"
else
  gcloud iam service-accounts create "$SA_NAME" \
    --project "$GCP_PROJECT" \
    --display-name "Aphelion Cloud Run deployer"
fi

echo "==> Binding IAM roles"
for ROLE in roles/run.admin roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding "$GCP_PROJECT" \
    --member "serviceAccount:$SA_EMAIL" \
    --role "$ROLE" \
    --condition=None \
    --quiet >/dev/null
  echo "    Bound $ROLE"
done

# --- Workload Identity Federation --------------------------------------------

echo "==> Creating Workload Identity Pool: $POOL_NAME"
if gcloud iam workload-identity-pools describe "$POOL_NAME" \
    --project "$GCP_PROJECT" --location global &>/dev/null; then
  echo "    Already exists, skipping creation"
else
  gcloud iam workload-identity-pools create "$POOL_NAME" \
    --project "$GCP_PROJECT" \
    --location global \
    --display-name "GitHub Actions"
fi

echo "==> Creating Workload Identity Provider: $PROVIDER_NAME"
if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --project "$GCP_PROJECT" --location global \
    --workload-identity-pool "$POOL_NAME" &>/dev/null; then
  echo "    Already exists, skipping creation"
else
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
    --project "$GCP_PROJECT" \
    --location global \
    --workload-identity-pool "$POOL_NAME" \
    --display-name "GitHub" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition "assertion.repository=='$GITHUB_REPO'"
fi

echo "==> Granting SA impersonation to GitHub Actions"
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project "$GCP_PROJECT" \
  --role "roles/iam.workloadIdentityUser" \
  --member "principalSet://iam.googleapis.com/projects/$GCP_PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$GITHUB_REPO" \
  --quiet >/dev/null

WIF_PROVIDER="projects/$GCP_PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"

echo ""
echo "==> Setup complete"
echo "    SA:       $SA_EMAIL"
echo "    WIF:      $WIF_PROVIDER"
echo ""
echo "==> Now set these in GitHub (Settings > Secrets and variables > Actions):"
echo ""
echo "    VARS:"
echo "      GCP_PROJECT_ID    = $GCP_PROJECT"
echo "      GCP_REGION        = $GCP_REGION"
echo "      CLOUD_RUN_SERVICE = $CLOUD_RUN_SERVICE"
echo ""
echo "    SECRETS:"
echo "      GCP_WIF_PROVIDER  = $WIF_PROVIDER"
echo "      GCP_SERVICE_ACCOUNT = $SA_EMAIL"
