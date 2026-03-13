#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${OPENAEON_IMAGE:-${AEONPROPHET_IMAGE:-openaeon:local}}"
CONFIG_DIR="${OPENAEON_CONFIG_DIR:-${AEONPROPHET_CONFIG_DIR:-$HOME/.openaeon}}"
WORKSPACE_DIR="${OPENAEON_WORKSPACE_DIR:-${AEONPROPHET_WORKSPACE_DIR:-$HOME/.openaeon/workspace}}"
PROFILE_FILE="${OPENAEON_PROFILE_FILE:-${AEONPROPHET_PROFILE_FILE:-$HOME/.profile}}"

PROFILE_MOUNT=()
if [[ -f "$PROFILE_FILE" ]]; then
  PROFILE_MOUNT=(-v "$PROFILE_FILE":/home/node/.profile:ro)
fi

echo "==> Build image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" -f "$ROOT_DIR/Dockerfile" "$ROOT_DIR"

echo "==> Run live model tests (profile keys)"
docker run --rm -t \
  --entrypoint bash \
  -e COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
  -e HOME=/home/node \
  -e NODE_OPTIONS=--disable-warning=ExperimentalWarning \
  -e OPENAEON_LIVE_TEST=1 \
  -e OPENAEON_LIVE_MODELS="${OPENAEON_LIVE_MODELS:-${AEONPROPHET_LIVE_MODELS:-modern}}" \
  -e OPENAEON_LIVE_PROVIDERS="${OPENAEON_LIVE_PROVIDERS:-${AEONPROPHET_LIVE_PROVIDERS:-}}" \
  -e OPENAEON_LIVE_MAX_MODELS="${OPENAEON_LIVE_MAX_MODELS:-${AEONPROPHET_LIVE_MAX_MODELS:-48}}" \
  -e OPENAEON_LIVE_MODEL_TIMEOUT_MS="${OPENAEON_LIVE_MODEL_TIMEOUT_MS:-${AEONPROPHET_LIVE_MODEL_TIMEOUT_MS:-}}" \
  -e OPENAEON_LIVE_REQUIRE_PROFILE_KEYS="${OPENAEON_LIVE_REQUIRE_PROFILE_KEYS:-${AEONPROPHET_LIVE_REQUIRE_PROFILE_KEYS:-}}" \
  -v "$CONFIG_DIR":/home/node/.openaeon \
  -v "$WORKSPACE_DIR":/home/node/.openaeon/workspace \
  "${PROFILE_MOUNT[@]}" \
  "$IMAGE_NAME" \
  -lc "set -euo pipefail; [ -f \"$HOME/.profile\" ] && source \"$HOME/.profile\" || true; cd /app && pnpm test:live"
