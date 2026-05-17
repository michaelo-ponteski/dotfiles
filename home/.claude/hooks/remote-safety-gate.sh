#!/usr/bin/env bash
# PreToolUse hook for Bash: gates risky remote git/GitHub operations.
# Returns "ask" permission decision to force user confirmation before:
#   git push, gh pr create, gh pr merge, gh auth, git remote set-url/add.
# Why: the remote-safety agent should run before these, but Claude may forget.
# This hook enforces a stop — the user can then approve, or tell Claude to
# invoke the remote-safety subagent first.

set -euo pipefail

input=$(</dev/stdin)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

patterns=(
  "git push"
  "gh pr create"
  "gh pr merge"
  "gh auth"
  "git remote set-url"
  "git remote add"
)

matched=""
for p in "${patterns[@]}"; do
  if [[ "$command" == *"$p"* ]]; then
    matched="$p"
    break
  fi
done

# Not a risky command — allow silently.
[ -z "$matched" ] && exit 0

reason="Detected '$matched'. Invoke the remote-safety subagent first to verify: correct GitHub account (github-private vs github-work), no secrets/large binaries staged, target branch not protected, no force-push to main/master."

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $reason
  }
}'
