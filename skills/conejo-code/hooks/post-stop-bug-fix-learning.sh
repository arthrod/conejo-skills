#!/bin/sh
# post-stop-bug-fix-learning.sh
# Stop hook
#
# When Claude finishes a reply, check whether the conversation involved fixing a bug.
# If it did and the bug-fix-learning process has not been run yet, prompt for it.
#
# Exit 0 = normal exit (reminder is injected into context via JSON output)

INPUT=$(cat)

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Check for signals that a bug was fixed in this conversation
BUG_SIGNALS=$(grep -c -i -E "bug|fix|repair|broken|issue|error|hotfix" "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

if [ "$BUG_SIGNALS" -lt 3 ]; then
  # Not enough bug-fix signals — no reminder needed
  exit 0
fi

# Check whether bug-fix-learning has already been run
BUG_LEARNING_DONE=$(grep -c -i -E "bug.fix.learning|bug.learning|bug learning|recorded.*bug|bug.*recorded" "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

if [ "$BUG_LEARNING_DONE" -gt 0 ]; then
  # bug-fix-learning already done — do not repeat the reminder
  exit 0
fi

# Use continue + stopReason to prompt Claude to ask the user about bug-fix-learning
cat <<EOF
{
  "continue": true,
  "stopReason": "Bug Fix Learning reminder: this conversation appears to have involved fixing a bug. Per conejo-code practice, after a fix you should run bug-fix-learning: 1. Analyse the root cause (what broke, why, is it general?). 2. Decide where to record the lesson (cookbook / memory / workflow / skip). 3. Record and report back. Please ask the user whether to run bug-fix-learning now."
}
EOF

exit 0
