---
summary: "CLI reference for `openaeon daemon` (legacy alias for gateway service management)"
read_when:
  - You still use `openaeon daemon ...` in scripts
  - You need service lifecycle commands (install/start/stop/restart/status)
title: "daemon"
---

# `openaeon daemon`

Legacy alias for Gateway service management commands.

`openaeon daemon ...` maps to the same service control surface as `openaeon gateway ...` service commands.

## Usage

```bash
openaeon daemon status
openaeon daemon install
openaeon daemon start
openaeon daemon stop
openaeon daemon restart
openaeon daemon uninstall
```

## Subcommands

- `status`: show service install state and probe Gateway health
- `install`: install service (`launchd`/`systemd`/`schtasks`)
- `uninstall`: remove service
- `start`: start service
- `stop`: stop service
- `restart`: restart service

## Common options

- `status`: `--url`, `--token`, `--password`, `--timeout`, `--no-probe`, `--deep`, `--json`
- `install`: `--port`, `--runtime <node|bun>`, `--token`, `--force`, `--json`
- lifecycle (`uninstall|start|stop|restart`): `--json`

## Prefer

Use [`openaeon gateway`](/cli/gateway) for current docs and examples.
