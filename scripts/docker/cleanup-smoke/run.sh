#!/usr/bin/env bash
set -euo pipefail

cd /repo

export OPENAEON_STATE_DIR="/tmp/openaeon-test"
export OPENAEON_CONFIG_PATH="${OPENAEON_STATE_DIR}/openaeon.json"

echo "==> Build"
pnpm build

echo "==> Seed state"
mkdir -p "${OPENAEON_STATE_DIR}/credentials"
mkdir -p "${OPENAEON_STATE_DIR}/agents/main/sessions"
echo '{}' >"${OPENAEON_CONFIG_PATH}"
echo 'creds' >"${OPENAEON_STATE_DIR}/credentials/marker.txt"
echo 'session' >"${OPENAEON_STATE_DIR}/agents/main/sessions/sessions.json"

echo "==> Reset (config+creds+sessions)"
pnpm openaeon reset --scope config+creds+sessions --yes --non-interactive

test ! -f "${OPENAEON_CONFIG_PATH}"
test ! -d "${OPENAEON_STATE_DIR}/credentials"
test ! -d "${OPENAEON_STATE_DIR}/agents/main/sessions"

echo "==> Recreate minimal config"
mkdir -p "${OPENAEON_STATE_DIR}/credentials"
echo '{}' >"${OPENAEON_CONFIG_PATH}"

echo "==> Uninstall (state only)"
pnpm openaeon uninstall --state --yes --non-interactive

test ! -d "${OPENAEON_STATE_DIR}"

echo "OK"
