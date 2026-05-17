#!/usr/bin/env bash
# Notification hook: fires a native macOS banner + sound when Claude Code
# emits a notification (input needed, permission request, task complete).
# Works in any terminal/IDE — WezTerm, VSCode, Terminal.app, etc.
# Replaces preferredNotifChannel so behavior is consistent across contexts.

set -euo pipefail

input=$(</dev/stdin)
msg=$(printf '%s' "$input" | jq -r '.message // .title // "Notification"')

# Escape double quotes for AppleScript
msg=${msg//\"/\\\"}

osascript -e "display notification \"$msg\" with title \"Claude Code\" sound name \"Glass\"" >/dev/null 2>&1 || true
exit 0
