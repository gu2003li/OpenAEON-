---
summary: "CLI reference for `openaeon devices` (device pairing + token rotation/revocation)"
read_when:
  - You are approving device pairing requests
  - You need to rotate or revoke device tokens
title: "devices"
---

# `openaeon devices`

Manage device pairing requests and device-scoped tokens.

## Commands

### `openaeon devices list`

List pending pairing requests and paired devices.

```
openaeon devices list
openaeon devices list --json
```

### `openaeon devices remove <deviceId>`

Remove one paired device entry.

```
openaeon devices remove <deviceId>
openaeon devices remove <deviceId> --json
```

### `openaeon devices clear --yes [--pending]`

Clear paired devices in bulk.

```
openaeon devices clear --yes
openaeon devices clear --yes --pending
openaeon devices clear --yes --pending --json
```

### `openaeon devices approve [requestId] [--latest]`

Approve a pending device pairing request. If `requestId` is omitted, OpenAEON
automatically approves the most recent pending request.

```
openaeon devices approve
openaeon devices approve <requestId>
openaeon devices approve --latest
```

### `openaeon devices reject <requestId>`

Reject a pending device pairing request.

```
openaeon devices reject <requestId>
```

### `openaeon devices rotate --device <id> --role <role> [--scope <scope...>]`

Rotate a device token for a specific role (optionally updating scopes).

```
openaeon devices rotate --device <deviceId> --role operator --scope operator.read --scope operator.write
```

### `openaeon devices revoke --device <id> --role <role>`

Revoke a device token for a specific role.

```
openaeon devices revoke --device <deviceId> --role node
```

## Common options

- `--url <url>`: Gateway WebSocket URL (defaults to `gateway.remote.url` when configured).
- `--token <token>`: Gateway token (if required).
- `--password <password>`: Gateway password (password auth).
- `--timeout <ms>`: RPC timeout.
- `--json`: JSON output (recommended for scripting).

Note: when you set `--url`, the CLI does not fall back to config or environment credentials.
Pass `--token` or `--password` explicitly. Missing explicit credentials is an error.

## Notes

- Token rotation returns a new token (sensitive). Treat it like a secret.
- These commands require `operator.pairing` (or `operator.admin`) scope.
- `devices clear` is intentionally gated by `--yes`.
- If pairing scope is unavailable on local loopback (and no explicit `--url` is passed), list/approve can use a local pairing fallback.
