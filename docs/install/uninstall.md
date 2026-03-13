---
summary: "Uninstall OpenAEON completely (CLI, service, state, workspace)"
read_when:
  - You want to remove OpenAEON from a machine
  - The gateway service is still running after uninstall
title: "Uninstall"
---

# Uninstall

Two paths:

- **Easy path** if `openaeon` is still installed.
- **Manual service removal** if the CLI is gone but the service is still running.

## Easy path (CLI still installed)

Recommended: use the built-in uninstaller:

```bash
openaeon uninstall
```

Non-interactive (automation / npx):

```bash
openaeon uninstall --all --yes --non-interactive
npx -y openaeon uninstall --all --yes --non-interactive
```

Manual steps (same result):

1. Stop the gateway service:

```bash
openaeon gateway stop
```

2. Uninstall the gateway service (launchd/systemd/schtasks):

```bash
openaeon gateway uninstall
```

3. Delete state + config:

```bash
rm -rf "${OPENAEON_STATE_DIR:-$HOME/.openaeon}"
```

If you set `OPENAEON_CONFIG_PATH` to a custom location outside the state dir, delete that file too.

4. Delete your workspace (optional, removes agent files):

```bash
rm -rf ~/.openaeon/workspace
```

5. Remove the CLI install (pick the one you used):

```bash
npm rm -g openaeon
pnpm remove -g openaeon
bun remove -g openaeon
```

6. If you installed the macOS app:

```bash
rm -rf /Applications/OpenAEON.app
```

Notes:

- If you used profiles (`--profile` / `OPENAEON_PROFILE`), repeat step 3 for each state dir (defaults are `~/.openaeon-<profile>`).
- In remote mode, the state dir lives on the **gateway host**, so run steps 1-4 there too.

## Manual service removal (CLI not installed)

Use this if the gateway service keeps running but `openaeon` is missing.

### macOS (launchd)

Default label is `ai.openaeon.gateway` (or `ai.openaeon.<profile>`; legacy `com.openaeon.*` may still exist):

```bash
launchctl bootout gui/$UID/ai.openaeon.gateway
rm -f ~/Library/LaunchAgents/ai.openaeon.gateway.plist
```

If you used a profile, replace the label and plist name with `ai.openaeon.<profile>`. Remove any legacy `com.openaeon.*` plists if present.

### Linux (systemd user unit)

Default unit name is `openaeon-gateway.service` (or `openaeon-gateway-<profile>.service`):

```bash
systemctl --user disable --now openaeon-gateway.service
rm -f ~/.config/systemd/user/openaeon-gateway.service
systemctl --user daemon-reload
```

### Windows (Scheduled Task)

Default task name is `OpenAEON Gateway` (or `OpenAEON Gateway (<profile>)`).
The task script lives under your state dir.

```powershell
schtasks /Delete /F /TN "OpenAEON Gateway"
Remove-Item -Force "$env:USERPROFILE\.openaeon\gateway.cmd"
```

If you used a profile, delete the matching task name and `~\.openaeon-<profile>\gateway.cmd`.

## Normal install vs source checkout

### Normal install (install.sh / npm / pnpm / bun)

If you used `https://openaeon.ai/install.sh` or `install.ps1`, the CLI was installed with `npm install -g openaeon@latest`.
Remove it with `npm rm -g openaeon` (or `pnpm remove -g` / `bun remove -g` if you installed that way).

### Source checkout (git clone)

If you run from a repo checkout (`git clone` + `openaeon ...` / `bun run openaeon ...`):

1. Uninstall the gateway service **before** deleting the repo (use the easy path above or manual service removal).
2. Delete the repo directory.
3. Remove state + workspace as shown above.
