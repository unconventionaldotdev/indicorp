#!/usr/bin/env bash
set -euo pipefail

# Image tag (override: IMAGE_TAG=mytag ./bin/build.sh)
IMAGE_TAG="${IMAGE_TAG:-unconventionaldotdev/indicorp:latest}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Building Docker image ${IMAGE_TAG}"
docker build -f "${ROOT_DIR}/Dockerfile" -t "${IMAGE_TAG}" "${ROOT_DIR}"

echo "==> Done"
