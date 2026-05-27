#!/usr/bin/env bash
# Mirror the four conejo-* skills to a deploy root and prune the 13 folded skills.
# Symlink-aware; refuses to delete locally-modified real directories.
# Usage: sync-to-claude.sh [--root <dir>] [--dry-run]
set -euo pipefail
ROOT="${HOME}/.claude/skills"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MIRROR="conejo conejo-code conejo-frontend conejo-merge"
PRUNE="refine-distill-frontend increase-impact-personality-frontend ui-ux-pro-max \
stitch-design-taste colorize typeset type-mania ux-design-brief shadcn-parity \
json-render tanstack-router tanstack-router-best-practices seo-audit"

for s in $MIRROR; do
  echo "mirror: $s -> $ROOT/$s"
  [ "$DRY" = "1" ] && continue
  rm -rf "$ROOT/$s"; mkdir -p "$ROOT/$s"
  cp -R "$REPO/skills/$s/." "$ROOT/$s/"
done

for s in $PRUNE; do
  t="$ROOT/$s"
  [ -e "$t" ] || continue
  if [ -L "$t" ]; then
    echo "prune symlink: $t"
    [ "$DRY" = "1" ] || rm -f "$t"
  elif [ -d "$t" ]; then
    if diff -rq "$t" "$REPO/skills/conejo-frontend/refs/$s" >/dev/null 2>&1; then
      echo "prune clean copy: $t"
      [ "$DRY" = "1" ] || rm -rf "$t"
    else
      echo "WARN: refusing to prune locally-modified $t (resolve manually)"
    fi
  fi
done
echo "sync complete${DRY:+ (dry-run)}"
