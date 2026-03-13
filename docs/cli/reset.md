---
summary: "CLI reference for `openaeon reset` (reset local state/config)"
read_when:
  - You want to wipe local state while keeping the CLI installed
  - You want a dry-run of what would be removed
title: "reset"
---

# `openaeon reset`

Reset local config/state (keeps the CLI installed).

```bash
openaeon reset
openaeon reset --dry-run
openaeon reset --scope config+creds+sessions --yes --non-interactive
```
