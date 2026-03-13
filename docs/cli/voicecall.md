---
summary: "CLI reference for `openaeon voicecall` (voice-call plugin command surface)"
read_when:
  - You use the voice-call plugin and want the CLI entry points
  - You want quick examples for `voicecall call|continue|status|tail|expose`
title: "voicecall"
---

# `openaeon voicecall`

`voicecall` is a plugin-provided command. It only appears if the voice-call plugin is installed and enabled.

Primary doc:

- Voice-call plugin: [Voice Call](/plugins/voice-call)

## Common commands

```bash
openaeon voicecall status --call-id <id>
openaeon voicecall call --to "+15555550123" --message "Hello" --mode notify
openaeon voicecall continue --call-id <id> --message "Any questions?"
openaeon voicecall end --call-id <id>
```

## Exposing webhooks (Tailscale)

```bash
openaeon voicecall expose --mode serve
openaeon voicecall expose --mode funnel
openaeon voicecall expose --mode off
```

Security note: only expose the webhook endpoint to networks you trust. Prefer Tailscale Serve over Funnel when possible.
