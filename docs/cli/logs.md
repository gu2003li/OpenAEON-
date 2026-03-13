---
summary: "CLI reference for `openaeon logs` (tail gateway logs via RPC)"
read_when:
  - You need to tail Gateway logs remotely (without SSH)
  - You want JSON log lines for tooling
title: "logs"
---

# `openaeon logs`

Tail Gateway file logs over RPC (works in remote mode).

Related:

- Logging overview: [Logging](/logging)

## Examples

```bash
openaeon logs
openaeon logs --follow
openaeon logs --json
openaeon logs --limit 500
openaeon logs --local-time
openaeon logs --follow --local-time
```

Use `--local-time` to render timestamps in your local timezone.
