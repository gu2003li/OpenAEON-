#!/data/data/com.termux/files/usr/bin/bash
# OpenAEON OAuth Sync Widget
# Syncs Claude Code tokens to OpenAEON on l36 server
# Place in ~/.shortcuts/ on phone for Termux:Widget

termux-toast "Syncing OpenAEON auth..."

# Run sync on l36 server
SERVER="${OPENAEON_SERVER:-${AEONPROPHET_SERVER:-l36}}"
RESULT=$(ssh "$SERVER" '/home/admin/openaeon/scripts/sync-claude-code-auth.sh' 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Extract expiry time from output
    EXPIRY=$(echo "$RESULT" | grep "Token expires:" | cut -d: -f2-)

    termux-vibrate -d 100
    termux-toast "OpenAEON synced! Expires:${EXPIRY}"

    # Optional: restart openaeon service
    ssh "$SERVER" 'systemctl --user restart openaeon' 2>/dev/null
else
    termux-vibrate -d 300
    termux-toast "Sync failed: ${RESULT}"
fi
