#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_IMAGE="${OPENAEON_INSTALL_SMOKE_IMAGE:-${AEONPROPHET_INSTALL_SMOKE_IMAGE:-openaeon-install-smoke:local}}"
NONROOT_IMAGE="${OPENAEON_INSTALL_NONROOT_IMAGE:-${AEONPROPHET_INSTALL_NONROOT_IMAGE:-openaeon-install-nonroot:local}}"
INSTALL_URL="${OPENAEON_INSTALL_URL:-${AEONPROPHET_INSTALL_URL:-https://openaeon.bot/install.sh}}"
CLI_INSTALL_URL="${OPENAEON_INSTALL_CLI_URL:-${AEONPROPHET_INSTALL_CLI_URL:-https://openaeon.bot/install-cli.sh}}"
SKIP_NONROOT="${OPENAEON_INSTALL_SMOKE_SKIP_NONROOT:-${AEONPROPHET_INSTALL_SMOKE_SKIP_NONROOT:-0}}"
LATEST_DIR="$(mktemp -d)"
LATEST_FILE="${LATEST_DIR}/latest"

echo "==> Build smoke image (upgrade, root): $SMOKE_IMAGE"
docker build \
  -t "$SMOKE_IMAGE" \
  -f "$ROOT_DIR/scripts/docker/install-sh-smoke/Dockerfile" \
  "$ROOT_DIR/scripts/docker/install-sh-smoke"

echo "==> Run installer smoke test (root): $INSTALL_URL"
docker run --rm -t \
  -v "${LATEST_DIR}:/out" \
  -e OPENAEON_INSTALL_URL="$INSTALL_URL" \
  -e OPENAEON_INSTALL_METHOD=npm \
  -e OPENAEON_INSTALL_LATEST_OUT="/out/latest" \
  -e OPENAEON_INSTALL_SMOKE_PREVIOUS="${OPENAEON_INSTALL_SMOKE_PREVIOUS:-${AEONPROPHET_INSTALL_SMOKE_PREVIOUS:-}}" \
  -e OPENAEON_INSTALL_SMOKE_SKIP_PREVIOUS="${OPENAEON_INSTALL_SMOKE_SKIP_PREVIOUS:-${AEONPROPHET_INSTALL_SMOKE_SKIP_PREVIOUS:-0}}" \
  -e OPENAEON_NO_ONBOARD=1 \
  -e DEBIAN_FRONTEND=noninteractive \
  "$SMOKE_IMAGE"

LATEST_VERSION=""
if [[ -f "$LATEST_FILE" ]]; then
  LATEST_VERSION="$(cat "$LATEST_FILE")"
fi

if [[ "$SKIP_NONROOT" == "1" ]]; then
  echo "==> Skip non-root installer smoke (OPENAEON_INSTALL_SMOKE_SKIP_NONROOT=1)"
else
  echo "==> Build non-root image: $NONROOT_IMAGE"
  docker build \
    -t "$NONROOT_IMAGE" \
    -f "$ROOT_DIR/scripts/docker/install-sh-nonroot/Dockerfile" \
    "$ROOT_DIR/scripts/docker/install-sh-nonroot"

  echo "==> Run installer non-root test: $INSTALL_URL"
  docker run --rm -t \
    -e OPENAEON_INSTALL_URL="$INSTALL_URL" \
    -e OPENAEON_INSTALL_METHOD=npm \
    -e OPENAEON_INSTALL_EXPECT_VERSION="$LATEST_VERSION" \
    -e OPENAEON_NO_ONBOARD=1 \
    -e DEBIAN_FRONTEND=noninteractive \
    "$NONROOT_IMAGE"
fi

if [[ "${OPENAEON_INSTALL_SMOKE_SKIP_CLI:-${AEONPROPHET_INSTALL_SMOKE_SKIP_CLI:-0}}" == "1" ]]; then
  echo "==> Skip CLI installer smoke (OPENAEON_INSTALL_SMOKE_SKIP_CLI=1)"
  exit 0
fi

if [[ "$SKIP_NONROOT" == "1" ]]; then
  echo "==> Skip CLI installer smoke (non-root image skipped)"
  exit 0
fi

echo "==> Run CLI installer non-root test (same image)"
docker run --rm -t \
  --entrypoint /bin/bash \
  -e OPENAEON_INSTALL_URL="$INSTALL_URL" \
  -e OPENAEON_INSTALL_CLI_URL="$CLI_INSTALL_URL" \
  -e OPENAEON_NO_ONBOARD=1 \
  -e DEBIAN_FRONTEND=noninteractive \
  "$NONROOT_IMAGE" -lc "curl -fsSL \"$CLI_INSTALL_URL\" | bash -s -- --set-npm-prefix --no-onboard"
