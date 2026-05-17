#!/usr/bin/env bash
# Removes skills from the document-skills plugin cache that the user does not use.
# Idempotent — safe to run on every SessionStart; instant no-op if already pruned.
# Why: Claude Code has no per-skill disable for plugin skills, and plugin updates
# restore deleted skill directories. This re-prunes them.

set -euo pipefail

CACHE_BASE="$HOME/.claude/plugins/cache/anthropic-agent-skills/document-skills"

# Note: docx and pptx are EXCLUDED — they are explicitly listed in the
# plugin manifest as required skills, so deleting them causes "skills path not
# found" errors on every session start. They are hidden via skillOverrides
# in ~/.claude/settings.json instead.
SKILLS_TO_REMOVE=(
  algorithmic-art
  brand-guidelines
  canvas-design
  doc-coauthoring
  frontend-design
  internal-comms
  slack-gif-creator
  theme-factory
  web-artifacts-builder
)

removed_any=0
for version_dir in "$CACHE_BASE"/*/; do
  [ -d "$version_dir" ] || continue
  for skill in "${SKILLS_TO_REMOVE[@]}"; do
    skill_path="${version_dir}skills/${skill}"
    if [ -d "$skill_path" ]; then
      rm -rf "$skill_path"
      removed_any=1
    fi
  done
done

if [ "$removed_any" = "1" ]; then
  echo "{\"systemMessage\":\"Pruned unwanted skills from document-skills cache (likely after plugin update).\"}"
fi

exit 0
