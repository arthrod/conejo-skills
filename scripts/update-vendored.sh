#!/usr/bin/env bash
# update-vendored.sh — Refresh vendored skills from their upstream GitHub sources.
#
# Reads scripts/vendored-sources.tsv (4 columns: name, repo, path-in-repo, verdict)
# and for each skill marked as a "mere copy" of an upstream:
#   1. Downloads the upstream SKILL.md (and references/, if present)
#   2. Re-injects our standard cross-ref + Stitch-first blocks (for design skills)
#   3. Updates ./skills/<name>/ with the refreshed content
#
# Skills marked CUSTOMIZED are skipped — they have local edits worth preserving.
# Skills marked LIGHT-EDIT print a warning but are NOT auto-updated; review manually.
#
# Usage:
#   ./scripts/update-vendored.sh                # update everything marked IDENTICAL or MERE-COPY
#   ./scripts/update-vendored.sh <skill_name>   # update one specific skill
#   DRY_RUN=1 ./scripts/update-vendored.sh      # show what would change, don't modify
#   FORCE=1 ./scripts/update-vendored.sh        # include LIGHT-EDIT skills too
#
# Requires: gh CLI authenticated, jq

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TSV="$REPO_ROOT/scripts/vendored-sources.tsv"
SKILLS_DIR="$REPO_ROOT/skills"
DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"
TARGET_SKILL="${1:-}"

if [ ! -f "$TSV" ]; then
  echo "ERROR: $TSV not found" >&2
  exit 1
fi

command -v gh >/dev/null || { echo "ERROR: gh CLI required" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq required" >&2; exit 1; }

updated=0
skipped_customized=0
skipped_warning=0
errors=0

while IFS=$'\t' read -r name repo skill_path verdict ours_ups diff_count actual_path; do
  [ -z "$name" ] && continue
  [ "$name" = "name" ] && continue   # header row
  [ -n "$TARGET_SKILL" ] && [ "$name" != "$TARGET_SKILL" ] && continue

  # Skip customized — local edits are valuable
  if [ "$verdict" = "CUSTOMIZED" ]; then
    skipped_customized=$((skipped_customized+1))
    continue
  fi

  # Skip light-edits unless FORCE
  if [ "$verdict" = "LIGHT-EDIT" ] && [ "$FORCE" != "1" ]; then
    echo "WARN  $name has local edits (LIGHT-EDIT). Use FORCE=1 to overwrite. Skipping."
    skipped_warning=$((skipped_warning+1))
    continue
  fi

  # Only process IDENTICAL, MERE-COPY (and LIGHT-EDIT under FORCE)
  case "$verdict" in
    IDENTICAL|MERE-COPY|LIGHT-EDIT) ;;
    *) continue ;;
  esac

  target_dir="$SKILLS_DIR/$name"
  if [ ! -d "$target_dir" ]; then
    echo "MISS  $name not present in skills/; skipping"
    continue
  fi

  echo "==> $name  (from $repo : $actual_path)"

  # Fetch upstream SKILL.md
  if ! upstream_content=$(gh api "repos/$repo/contents/$actual_path" --jq '.content' 2>/dev/null | base64 -d); then
    echo "  ERROR: could not fetch $repo/$actual_path"
    errors=$((errors+1))
    continue
  fi
  [ -z "$upstream_content" ] && { echo "  ERROR: empty content"; errors=$((errors+1)); continue; }

  # Preserve our local cross-ref block + Stitch block (extract from current SKILL.md)
  current="$target_dir/SKILL.md"
  cross_ref_block=$(awk '/<!-- cross-ref:start -->/,/<!-- cross-ref:end -->/' "$current" 2>/dev/null || true)

  # Build new SKILL.md
  tmp=$(mktemp)
  echo "$upstream_content" > "$tmp"

  # Append "vendored from" footer if not already present (idempotent marker)
  if ! grep -q "<!-- vendored:start -->" "$tmp"; then
    cat >> "$tmp" <<EOF

<!-- vendored:start -->

## Source

Vendored from [\`$repo\`](https://github.com/$repo/blob/main/$actual_path) on $(date -u +%Y-%m-%d).
Refresh with: \`./scripts/update-vendored.sh $name\`

<!-- vendored:end -->
EOF
  fi

  # Re-append cross-ref block if we had one
  if [ -n "$cross_ref_block" ]; then
    echo "" >> "$tmp"
    echo "$cross_ref_block" >> "$tmp"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  DRY_RUN: would update $current (was $(wc -l < "$current") lines, new $(wc -l < "$tmp") lines)"
    rm -f "$tmp"
  else
    mv "$tmp" "$current"
    echo "  updated $current"
    updated=$((updated+1))
  fi

  # Try to fetch references/ subfolder too if upstream has one
  if upstream_refs=$(gh api "repos/$repo/contents/${actual_path%/SKILL.md}/references" --jq '.[].name' 2>/dev/null); then
    mkdir -p "$target_dir/references"
    for ref in $upstream_refs; do
      ref_path="${actual_path%/SKILL.md}/references/$ref"
      if ref_content=$(gh api "repos/$repo/contents/$ref_path" --jq '.content' 2>/dev/null | base64 -d); then
        if [ "$DRY_RUN" = "1" ]; then
          echo "  DRY_RUN: would refresh references/$ref"
        else
          echo "$ref_content" > "$target_dir/references/$ref"
          echo "  refreshed references/$ref"
        fi
      fi
    done
  fi
done < "$TSV"

echo
echo "Summary:"
echo "  Updated: $updated"
echo "  Skipped (CUSTOMIZED, local edits preserved): $skipped_customized"
echo "  Warned (LIGHT-EDIT, use FORCE=1): $skipped_warning"
echo "  Errors: $errors"
