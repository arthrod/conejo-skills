#!/usr/bin/env bash
# refresh-superpowers.sh — pull obra/superpowers into ./superpowers (git-ignored),
# copy every upstream skill over ./skills/<name>/ (scripts, prompts, references and
# all), then re-apply this repo's <!-- conejo:start --> … <!-- conejo:end --> block
# and a fresh "vendored" footer to each SKILL.md.
#
# Upstream prose is never edited in place: local rules live only in the conejo block,
# so a refresh is a clean replace + re-append.
#
# Usage:
#   ./scripts/refresh-superpowers.sh              # pull main, refresh all
#   REF=v7.0.2 ./scripts/refresh-superpowers.sh   # pin a tag/branch/SHA
#   DRY_RUN=1 ./scripts/refresh-superpowers.sh    # show what would change
#   ./scripts/refresh-superpowers.sh writing-plans executing-plans   # subset
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/superpowers"
SKILLS_DIR="$REPO_ROOT/skills"
UPSTREAM="https://github.com/obra/superpowers"
REF="${REF:-main}"
DRY_RUN="${DRY_RUN:-0}"
ONLY=("$@")

if [ -d "$SRC/.git" ]; then
  git -C "$SRC" fetch --tags --quiet origin
  git -C "$SRC" checkout --quiet "$REF" 2>/dev/null || git -C "$SRC" checkout --quiet "origin/$REF"
  git -C "$SRC" pull --ff-only --quiet origin "$REF" 2>/dev/null || true
else
  git clone --quiet "$UPSTREAM" "$SRC"
  git -C "$SRC" checkout --quiet "$REF"
fi
SHA=$(git -C "$SRC" rev-parse --short=7 HEAD)
TAG=$(git -C "$SRC" describe --tags --exact-match 2>/dev/null || git -C "$SRC" describe --tags --always)
TODAY=$(date -u +%Y-%m-%d)
grep -qx 'superpowers/' "$REPO_ROOT/.gitignore" || echo "WARN: superpowers/ is not in .gitignore" >&2

want() { [ ${#ONLY[@]} -eq 0 ] && return 0; for o in "${ONLY[@]}"; do [ "$o" = "$1" ] && return 0; done; return 1; }

refreshed=0
for d in "$SRC"/skills/*/; do
  name=$(basename "$d"); want "$name" || continue
  target="$SKILLS_DIR/$name"
  block=""
  [ -f "$target/SKILL.md" ] && block=$(awk '/<!-- conejo:start -->/,/<!-- conejo:end -->/' "$target/SKILL.md")
  if [ "$DRY_RUN" = "1" ]; then
    echo "DRY  $name  ← $TAG ($SHA)  conejo-block: $([ -n "$block" ] && echo kept || echo none)"
    continue
  fi
  rm -rf "$target"; cp -R "$d" "$target"
  {
    printf '\n<!-- vendored:start -->\n\n## Source\n\n'
    printf 'Vendored from [`obra/superpowers`](%s/tree/%s/skills/%s) **%s** (`%s`) on %s.\n' "$UPSTREAM" "$TAG" "$name" "$TAG" "$SHA" "$TODAY"
    printf 'Refresh with `./scripts/refresh-superpowers.sh` from the conejo-skills repo — the `<!-- conejo -->` block below is re-applied automatically; upstream text above it is left verbatim.\n\n<!-- vendored:end -->\n'
    [ -n "$block" ] && printf '\n%s\n' "$block"
  } >> "$target/SKILL.md"
  echo "ok   $name  ← $TAG ($SHA)  conejo-block: $([ -n "$block" ] && echo re-applied || echo none)"
  refreshed=$((refreshed+1))
done
echo "refreshed: $refreshed skill(s) from obra/superpowers $TAG ($SHA)"
echo "next: review \`git diff --stat skills/\`, then ./scripts/update-skills.sh --skip-vendored to publish"
