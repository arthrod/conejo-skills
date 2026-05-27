#!/usr/bin/env bash
# Idempotently merge conejo-code's hooks into a Claude Code settings.json.
# Usage: install-conejo-hooks.sh [--settings <path>] [--dry-run]
set -euo pipefail
SETTINGS="${HOME}/.claude/settings.json"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --settings) SETTINGS="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills/conejo-code/hooks"
PRE="$HOOK_DIR/pre-edit-cookbook-check.sh"
POST="$HOOK_DIR/post-stop-bug-fix-learning.sh"

if [ "$DRY" = "1" ]; then
  echo "Would add to $SETTINGS:"
  echo "  PreToolUse(Edit|Write) -> $PRE"
  echo "  Stop -> $POST"
  exit 0
fi

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
node - "$SETTINGS" "$PRE" "$POST" <<'NODE'
const fs = require('fs');
const [file, pre, post] = process.argv.slice(2);
const s = JSON.parse(fs.readFileSync(file, 'utf8'));
s.hooks = s.hooks || {};
const ensure = (event, matcher, cmd) => {
  s.hooks[event] = s.hooks[event] || [];
  const exists = JSON.stringify(s.hooks[event]).includes(cmd);
  if (!exists) s.hooks[event].push({ matcher, hooks: [{ type: 'command', command: cmd }] });
};
ensure('PreToolUse', 'Edit|Write', pre);
ensure('Stop', '', post);
fs.writeFileSync(file, JSON.stringify(s, null, 2) + '\n');
console.log('conejo hooks installed in ' + file);
NODE
