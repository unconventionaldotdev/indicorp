#!/usr/bin/env bash
set -euo pipefail

# Image tag (override: IMAGE_TAG=mytag ./bin/build.sh)
IMAGE_TAG="${IMAGE_TAG:-unconventionaldotdev/indicorp:latest}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/plugins/indico-plugins"
DIST_DIR="${ROOT_DIR}/dist"

if ! command -v uv >/dev/null 2>&1; then
  echo "error: uv not found in PATH" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx not found in PATH" >&2
  exit 1
fi

# Ensure submodules are initialized (safe if already)
git -C "${ROOT_DIR}" submodule update --init --recursive

echo "==> Cleaning dist"
rm -rf "${DIST_DIR}"

echo "==> Building indico wheel"
# indico/bin/maintenance/build-wheel.py indico

# TODO: Fix build for plugins
# echo "==> Building indico-plugins wheel"
# indico/bin/maintenance/build-wheel.py all-plugins "${PLUGINS_DIR}"

echo "==> Building distribution wheel"
indico/bin/maintenance/build-wheel.py plugin --no-git "${ROOT_DIR}"

echo "==> Contents of dist/"
ls -1 "${DIST_DIR}"

echo "==> Building Docker image ${IMAGE_TAG}"
docker build -f "${ROOT_DIR}/Dockerfile" -t "${IMAGE_TAG}" "${ROOT_DIR}"

echo "==> Done"
