#!/bin/bash
# DEPRECATED (Wave 1+2): Docker Hub pushes are banned.
# Use GitHub Actions (build-push-ecr.yml) or ./build_push_to_ecr.sh (ECR sha-* only).

set -euo pipefail

echo "ERROR: build_and_push.sh (Docker Hub / asfas244) is retired." >&2
echo "  - Normal path: push to main → GHA → ECR sha-* → manifests promotion PR" >&2
echo "  - Emergency:   ./build_push_to_ecr.sh   (or rebuild-ecr-image-pins.ps1 -NewTag)" >&2
exit 1
