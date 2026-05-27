#!/bin/sh
# pre-edit-cookbook-check.sh
# PreToolUse hook (matcher: Edit|Write)
#
# Before writing code, check whether the current session has already read the
# cookbook and memory files. Decision is made by scanning the transcript.
# If transcript records show both were read, the edit is allowed through.
#
# Exit 0 = allow (already read, or not a code file)
# Exit 2 = block  (cookbook/memory not yet read — ask Claude to read them first)
#
# NOTE — project-layout assumptions (arthrod's setup):
#   This hook is tailored to a layout where the cookbook lives at docs/cookbook/
#   and per-session memory feedback files match the pattern MEMORY.md /
#   feedback_*.md.  If you adopt this hook in a different project, update the
#   grep patterns on the COOKBOOK_READ and MEMORY_READ lines below to match
#   your actual paths and file-naming conventions.

INPUT=$(cat)

# Obtain the file path being edited
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only gate code files; pass non-code files straight through
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.vue|*.py|*.go|*.rs|*.java|*.kt|*.swift|*.rb|*.php|*.css|*.scss)
    # Continue to check
    ;;
  *)
    # Non-code file (markdown, json, config, etc.) — allow immediately
    exit 0
    ;;
esac

# Read transcript to check whether cookbook or memory has been consulted
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  # No transcript available — allow rather than block normal use
  exit 0
fi

# Search transcript for evidence that cookbook and memory were read
COOKBOOK_READ=$(grep -c -iE "cookbook|docs/cookbook" "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
MEMORY_READ=$(grep -c -iE "memory.*feedback|feedback_.*\.md|MEMORY\.md" "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

if [ "$COOKBOOK_READ" -gt 0 ] && [ "$MEMORY_READ" -gt 0 ]; then
  # Both cookbook and memory already read — allow
  exit 0
fi

# Build a list of what is still missing
MISSING=""
if [ "$COOKBOOK_READ" -eq 0 ]; then
  MISSING="the docs/cookbook/ documents"
fi
if [ "$MEMORY_READ" -eq 0 ]; then
  if [ -n "$MISSING" ]; then
    MISSING="$MISSING and "
  fi
  MISSING="${MISSING}the memory feedback records"
fi

# Use exit 2 + stderr to block the tool call and prompt Claude to read first
cat >&2 <<EOF
Pre-edit knowledge check failed: you have not yet read ${MISSING}.

Before writing code you must:
1. Read docs/cookbook/README.md for a quick overview and locate relevant docs.
2. Read the memory feedback records to recall past lessons learned.
3. Analyse the existing patterns in the file you are about to modify.

Please complete the pre-edit checks before continuing. This edit has been blocked.
EOF

exit 2
