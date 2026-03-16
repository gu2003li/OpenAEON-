#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "usage: run-node-tool.sh <tool> [args...]" >&2
  exit 2
fi

tool="$1"
shift

if [[ -f "$ROOT_DIR/pnpm-lock.yaml" ]] && command -v pnpm >/dev/null 2>&1; then
  cd "$ROOT_DIR"
  if ! pnpm exec "$tool" --version >/dev/null 2>&1 && [[ ! -x "$ROOT_DIR/node_modules/.bin/$tool" ]]; then
    echo "Warning: tool '$tool' not found via pnpm, skipping..." >&2
    exit 0
  fi
  exec pnpm exec "$tool" "$@"
fi

if { [[ -f "$ROOT_DIR/bun.lockb" ]] || [[ -f "$ROOT_DIR/bun.lock" ]]; } && command -v bun >/dev/null 2>&1; then
  cd "$ROOT_DIR"
  exec bunx --bun "$tool" "$@"
fi

if command -v npm >/dev/null 2>&1; then
  cd "$ROOT_DIR"
  if ! npm exec -- "$tool" --version >/dev/null 2>&1 && [[ ! -x "$ROOT_DIR/node_modules/.bin/$tool" ]]; then
    echo "Warning: tool '$tool' not found via npm, skipping..." >&2
    exit 0
  fi
  exec npm exec -- "$tool" "$@"
fi

if command -v npx >/dev/null 2>&1; then
  cd "$ROOT_DIR"
  if ! npx "$tool" --version >/dev/null 2>&1 && [[ ! -x "$ROOT_DIR/node_modules/.bin/$tool" ]]; then
    echo "Warning: tool '$tool' not found via npx, skipping..." >&2
    exit 0
  fi
  exec npx "$tool" "$@"
fi

echo "Missing package manager: pnpm, bun, or npm required." >&2
exit 1
