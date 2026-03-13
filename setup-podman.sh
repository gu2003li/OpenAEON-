#!/usr/bin/env bash
# One-time host setup for rootless OPENAEON in Podman: creates the openaeon
# user, builds the image, loads it into that user's Podman store, and installs
# the launch script. Run from repo root with sudo capability.
#
# Usage: ./setup-podman.sh [--quadlet|--container]
#   --quadlet   Install systemd Quadlet so the container runs as a user service
#   --container Only install user + image + launch script; you start the container manually (default)
#   Or set OPENAEON_PODMAN_QUADLET=1 (or 0) to choose without a flag.
#
# After this, start the gateway manually:
#   ./scripts/run-openaeon-podman.sh launch
#   ./scripts/run-openaeon-podman.sh launch setup   # onboarding wizard
# Or as the openaeon user: sudo -u openaeon /home/openaeon/run-openaeon-podman.sh
# If you used --quadlet, you can also: sudo systemctl --machine openaeon@ --user start openaeon.service
set -euo pipefail

OPENAEON_USER="${OPENAEON_PODMAN_USER:-openaeon}"
REPO_PATH="${OPENAEON_REPO_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
RUN_SCRIPT_SRC="$REPO_PATH/scripts/run-openaeon-podman.sh"
QUADLET_TEMPLATE="$REPO_PATH/scripts/podman/openaeon.container.in"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

is_root() { [[ "$(id -u)" -eq 0 ]]; }

run_root() {
  if is_root; then
    "$@"
  else
    sudo "$@"
  fi
}

run_as_user() {
  local user="$1"
  shift
  if command -v sudo >/dev/null 2>&1; then
    sudo -u "$user" "$@"
  elif is_root && command -v runuser >/dev/null 2>&1; then
    runuser -u "$user" -- "$@"
  else
    echo "Need sudo (or root+runuser) to run commands as $user." >&2
    exit 1
  fi
}

run_as_openaeon() {
  # Avoid root writes into $OPENAEON_HOME (symlink/hardlink/TOCTOU footguns).
  # Anything under the target user's home should be created/modified as that user.
  run_as_user "$OPENAEON_USER" env HOME="$OPENAEON_HOME" "$@"
}

escape_sed_replacement_pipe_delim() {
  # Escape replacement metacharacters for sed "s|...|...|g" replacement text.
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# Quadlet: opt-in via --quadlet or OPENAEON_PODMAN_QUADLET=1
INSTALL_QUADLET=false
for arg in "$@"; do
  case "$arg" in
    --quadlet)   INSTALL_QUADLET=true ;;
    --container) INSTALL_QUADLET=false ;;
  esac
done
if [[ -n "${OPENAEON_PODMAN_QUADLET:-}" ]]; then
  case "${OPENAEON_PODMAN_QUADLET,,}" in
    1|yes|true)  INSTALL_QUADLET=true ;;
    0|no|false) INSTALL_QUADLET=false ;;
  esac
fi

require_cmd podman
if ! is_root; then
  require_cmd sudo
fi
if [[ ! -f "$REPO_PATH/Dockerfile" ]]; then
  echo "Dockerfile not found at $REPO_PATH. Set OPENAEON_REPO_PATH to the repo root." >&2
  exit 1
fi
if [[ ! -f "$RUN_SCRIPT_SRC" ]]; then
  echo "Launch script not found at $RUN_SCRIPT_SRC." >&2
  exit 1
fi

generate_token_hex_32() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
    return 0
  fi
  if command -v od >/dev/null 2>&1; then
    # 32 random bytes -> 64 lowercase hex chars
    od -An -N32 -tx1 /dev/urandom | tr -d " \n"
    return 0
  fi
  echo "Missing dependency: need openssl or python3 (or od) to generate OPENAEON_GATEWAY_TOKEN." >&2
  exit 1
}

user_exists() {
  local user="$1"
  if command -v getent >/dev/null 2>&1; then
    getent passwd "$user" >/dev/null 2>&1 && return 0
  fi
  id -u "$user" >/dev/null 2>&1
}

resolve_user_home() {
  local user="$1"
  local home=""
  if command -v getent >/dev/null 2>&1; then
    home="$(getent passwd "$user" 2>/dev/null | cut -d: -f6 || true)"
  fi
  if [[ -z "$home" && -f /etc/passwd ]]; then
    home="$(awk -F: -v u="$user" '$1==u {print $6}' /etc/passwd 2>/dev/null || true)"
  fi
  if [[ -z "$home" ]]; then
    home="/home/$user"
  fi
  printf '%s' "$home"
}

resolve_nologin_shell() {
  for cand in /usr/sbin/nologin /sbin/nologin /usr/bin/nologin /bin/false; do
    if [[ -x "$cand" ]]; then
      printf '%s' "$cand"
      return 0
    fi
  done
  printf '%s' "/usr/sbin/nologin"
}

# Create openaeon user (non-login, with home) if missing
if ! user_exists "$OPENAEON_USER"; then
  NOLOGIN_SHELL="$(resolve_nologin_shell)"
  echo "Creating user $OPENAEON_USER ($NOLOGIN_SHELL, with home)..."
  if command -v useradd >/dev/null 2>&1; then
    run_root useradd -m -s "$NOLOGIN_SHELL" "$OPENAEON_USER"
  elif command -v adduser >/dev/null 2>&1; then
    # Debian/Ubuntu: adduser supports --disabled-password/--gecos. Busybox adduser differs.
    run_root adduser --disabled-password --gecos "" --shell "$NOLOGIN_SHELL" "$OPENAEON_USER"
  else
    echo "Neither useradd nor adduser found, cannot create user $OPENAEON_USER." >&2
    exit 1
  fi
else
  echo "User $OPENAEON_USER already exists."
fi

OPENAEON_HOME="$(resolve_user_home "$OPENAEON_USER")"
OPENAEON_UID="$(id -u "$OPENAEON_USER" 2>/dev/null || true)"
OPENAEON_CONFIG="$OPENAEON_HOME/.openaeon"
LAUNCH_SCRIPT_DST="$OPENAEON_HOME/run-openaeon-podman.sh"

# Prefer systemd user services (Quadlet) for production. Enable lingering early so rootless Podman can run
# without an interactive login.
if command -v loginctl &>/dev/null; then
  run_root loginctl enable-linger "$OPENAEON_USER" 2>/dev/null || true
fi
if [[ -n "${OPENAEON_UID:-}" && -d /run/user ]] && command -v systemctl &>/dev/null; then
  run_root systemctl start "user@${OPENAEON_UID}.service" 2>/dev/null || true
fi

# Rootless Podman needs subuid/subgid for the run user
if ! grep -q "^${OPENAEON_USER}:" /etc/subuid 2>/dev/null; then
  echo "Warning: $OPENAEON_USER has no subuid range. Rootless Podman may fail." >&2
  echo "  Add a line to /etc/subuid and /etc/subgid, e.g.: $OPENAEON_USER:100000:65536" >&2
fi

echo "Creating $OPENAEON_CONFIG and workspace..."
run_as_openaeon mkdir -p "$OPENAEON_CONFIG/workspace"
run_as_openaeon chmod 700 "$OPENAEON_CONFIG" "$OPENAEON_CONFIG/workspace" 2>/dev/null || true

ENV_FILE="$OPENAEON_CONFIG/.env"
if run_as_openaeon test -f "$ENV_FILE"; then
  if ! run_as_openaeon grep -q '^OPENAEON_GATEWAY_TOKEN=' "$ENV_FILE" 2>/dev/null; then
    TOKEN="$(generate_token_hex_32)"
    printf 'OPENAEON_GATEWAY_TOKEN=%s\n' "$TOKEN" | run_as_openaeon tee -a "$ENV_FILE" >/dev/null
    echo "Added OPENAEON_GATEWAY_TOKEN to $ENV_FILE."
  fi
  run_as_openaeon chmod 600 "$ENV_FILE" 2>/dev/null || true
else
  TOKEN="$(generate_token_hex_32)"
  printf 'OPENAEON_GATEWAY_TOKEN=%s\n' "$TOKEN" | run_as_openaeon tee "$ENV_FILE" >/dev/null
  run_as_openaeon chmod 600 "$ENV_FILE" 2>/dev/null || true
  echo "Created $ENV_FILE with new token."
fi

# The gateway refuses to start unless gateway.mode=local is set in config.
# Make first-run non-interactive; users can run the wizard later to configure channels/providers.
OPENAEON_JSON="$OPENAEON_CONFIG/openaeon.json"
if ! run_as_openaeon test -f "$OPENAEON_JSON"; then
  printf '%s\n' '{ gateway: { mode: "local" } }' | run_as_openaeon tee "$OPENAEON_JSON" >/dev/null
  run_as_openaeon chmod 600 "$OPENAEON_JSON" 2>/dev/null || true
  echo "Created $OPENAEON_JSON (minimal gateway.mode=local)."
fi

echo "Building image from $REPO_PATH..."
podman build -t openaeon:local -f "$REPO_PATH/Dockerfile" "$REPO_PATH"

echo "Loading image into $OPENAEON_USER's Podman store..."
TMP_IMAGE="$(mktemp -p /tmp openaeon-image.XXXXXX.tar)"
trap 'rm -f "$TMP_IMAGE"' EXIT
podman save openaeon:local -o "$TMP_IMAGE"
chmod 644 "$TMP_IMAGE"
(cd /tmp && run_as_user "$OPENAEON_USER" env HOME="$OPENAEON_HOME" podman load -i "$TMP_IMAGE")
rm -f "$TMP_IMAGE"
trap - EXIT

echo "Copying launch script to $LAUNCH_SCRIPT_DST..."
run_root cat "$RUN_SCRIPT_SRC" | run_as_openaeon tee "$LAUNCH_SCRIPT_DST" >/dev/null
run_as_openaeon chmod 755 "$LAUNCH_SCRIPT_DST"

# Optionally install systemd quadlet for openaeon user (rootless Podman + systemd)
QUADLET_DIR="$OPENAEON_HOME/.config/containers/systemd"
if [[ "$INSTALL_QUADLET" == true && -f "$QUADLET_TEMPLATE" ]]; then
  echo "Installing systemd quadlet for $OPENAEON_USER..."
  run_as_openaeon mkdir -p "$QUADLET_DIR"
  OPENAEON_HOME_SED="$(escape_sed_replacement_pipe_delim "$OPENAEON_HOME")"
  sed "s|{{OPENAEON_HOME}}|$OPENAEON_HOME_SED|g" "$QUADLET_TEMPLATE" | run_as_openaeon tee "$QUADLET_DIR/openaeon.container" >/dev/null
  run_as_openaeon chmod 700 "$OPENAEON_HOME/.config" "$OPENAEON_HOME/.config/containers" "$QUADLET_DIR" 2>/dev/null || true
  run_as_openaeon chmod 600 "$QUADLET_DIR/openaeon.container" 2>/dev/null || true
  if command -v systemctl &>/dev/null; then
    run_root systemctl --machine "${OPENAEON_USER}@" --user daemon-reload 2>/dev/null || true
    run_root systemctl --machine "${OPENAEON_USER}@" --user enable openaeon.service 2>/dev/null || true
    run_root systemctl --machine "${OPENAEON_USER}@" --user start openaeon.service 2>/dev/null || true
  fi
fi

echo ""
echo "Setup complete. Start the gateway:"
echo "  $RUN_SCRIPT_SRC launch"
echo "  $RUN_SCRIPT_SRC launch setup   # onboarding wizard"
echo "Or as $OPENAEON_USER (e.g. from cron):"
echo "  sudo -u $OPENAEON_USER $LAUNCH_SCRIPT_DST"
echo "  sudo -u $OPENAEON_USER $LAUNCH_SCRIPT_DST setup"
if [[ "$INSTALL_QUADLET" == true ]]; then
  echo "Or use systemd (quadlet):"
  echo "  sudo systemctl --machine ${OPENAEON_USER}@ --user start openaeon.service"
  echo "  sudo systemctl --machine ${OPENAEON_USER}@ --user status openaeon.service"
else
  echo "To install systemd quadlet later: $0 --quadlet"
fi
