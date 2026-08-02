#!/bin/bash
# Local emergency push to Amazon ECR (Wave 1+2).
# Pushes a single immutable tag: sha-<12> from HEAD (or IMAGE_TAG env override).
# Docker Hub pushes are removed — use GHA on main for normal delivery.

set -euo pipefail

REGION="${AWS_REGION:-ap-northeast-2}"
SERVICES=(
  "edge-service"
  "store-service"
  "cart-service"
  "order-service"
  "payment-service"
  "user-service"
)

if [ -n "${IMAGE_TAG:-}" ]; then
  TAG="$IMAGE_TAG"
else
  TAG="sha-$(git -C "$(dirname "$0")/.." rev-parse --short=12 HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
fi

if [ "$TAG" = "latest" ]; then
  echo "Refusing banned tag 'latest' (ECR IMMUTABLE contract)." >&2
  exit 1
fi

echo "=================================================="
echo "Localy MSA - AWS ECR build/push (tag=${TAG})"
echo "=================================================="

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo "Registry: ${ECR_REGISTRY}"

aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

for SERVICE in "${SERVICES[@]}"; do
  SERVICE_DIR="${BASE_DIR}/${SERVICE}"
  if [ ! -d "${SERVICE_DIR}" ]; then
    echo "Skip missing ${SERVICE}"
    continue
  fi
  IMAGE_URI="${ECR_REGISTRY}/${SERVICE}:${TAG}"
  echo "---- ${SERVICE} → ${IMAGE_URI}"
  docker buildx build \
    --platform linux/amd64 \
    --provenance=false \
    -t "${IMAGE_URI}" \
    --push \
    "${SERVICE_DIR}"
done

echo "Done. Update localy-manifests image-pins + overlay newTag to ${TAG}, then Argo sync."
