#!/usr/bin/env bash
# install.sh — symlinks files from ./home/ into $HOME
# Usage: ./install.sh [--dry-run]
#
# For each file in home/, creates a symlink at the corresponding path in $HOME.
# Existing files (non-symlinks) are backed up to <path>.bak before being replaced.
# Already-correct symlinks are skipped. Safe to re-run.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES_DIR/home"
DST="$HOME"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

[ -d "$SRC" ] || { echo "Source directory not found: $SRC"; exit 1; }

linked=0
skipped=0
backed_up=0

while IFS= read -r src_file; do
  rel="${src_file#$SRC/}"
  dst_file="$DST/$rel"
  dst_dir="$(dirname "$dst_file")"

  if [ ! -d "$dst_dir" ]; then
    echo "mkdir -p  $dst_dir"
    [ "$DRY_RUN" = "0" ] && mkdir -p "$dst_dir"
  fi

  # Already correctly linked?
  if [ -L "$dst_file" ] && [ "$(readlink "$dst_file")" = "$src_file" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  # Back up existing file
  if [ -e "$dst_file" ] || [ -L "$dst_file" ]; then
    echo "backup    $dst_file -> $dst_file.bak"
    [ "$DRY_RUN" = "0" ] && mv "$dst_file" "$dst_file.bak"
    backed_up=$((backed_up + 1))
  fi

  echo "link      $dst_file"
  [ "$DRY_RUN" = "0" ] && ln -s "$src_file" "$dst_file"
  linked=$((linked + 1))
done < <(find "$SRC" -type f)

echo
echo "Summary: $linked linked, $skipped already-correct, $backed_up backed up"
[ "$DRY_RUN" = "1" ] && echo "(dry run — no changes made)"
