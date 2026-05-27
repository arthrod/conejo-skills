
# deps-check — Dependency Lookup Before Editing

## Why This Matters

The most common cause of "fix A, break B" is that the editor doesn't know who else depends on A. Type-checking and tests can catch most regressions, but only if:

1. You know to run the tests
2. The tests cover that dependency path

Spending 5 seconds confirming "who imports me" before making a change converts after-the-fact debugging into an upfront decision.

## When to Trigger

Trigger automatically in these situations:

- Modifying files in `src/lib/`, `src/services/`, `src/utils/`, `src/hooks/`, shared components, or any other **file referenced from multiple places**
- Renaming, deleting, or moving a file or exported symbol
- Changing the signature or return type of an exported function
- The user says "refactor", "change the API", or "extract this"

**No need to trigger** in these situations:

- Adding a new file (nothing depends on it yet)
- Only changing private/local symbols with no export changes
- Pure style tweaks or copy changes
- The file being edited is a test file itself

## Execution Flow

### Step 1: Run the Script

Call `${CLAUDE_PLUGIN_ROOT}/skills/deps-check/scripts/deps-check.sh <file-path>`.

Only TypeScript / JavaScript projects are currently supported (`.ts` `.tsx` `.js` `.jsx` `.mts` `.cts`). Non-TS/JS files are skipped without interrupting the flow.

The script will:

1. Walk up from the file to find the nearest `package.json` as the project root
2. If the project has `madge` installed, use `madge --reverse` to list dependents
3. Otherwise fall back to `grep`, searching common directories (`src/`, `app/`, `lib/`, `test/`, etc.) for import statements
4. Output the dependent file paths and the specific symbols they reference (grep mode prints the matching line directly)

### Step 2: Interpret the Output

Choose a strategy based on the number of dependents found:

| Dependents | Strategy |
|------------|----------|
| 0 | Safe to change — proceed directly |
| 1–3 | Read each dependent file; confirm the change won't break it |
| 4+ | Report the blast radius to the user; confirm whether to split into multiple steps or add a deprecation shim |

### Step 3: Report

Before touching any code, summarise the impact in one or two sentences, for example:

> `noteService.ts` is imported by 12 files. `App.tsx`, `NoteList.tsx`, and `useNotes.ts` use `listNotes()`. I'm changing the return type of `listNotes`, so all three files will need to be updated. Shall I continue?

### Step 4: Make the Change

Start editing only after the user confirms. If new dependencies surface during editing (e.g. dynamic imports, re-exports), run the script again.

### Step 5: Final Validation

After the changes are complete, run a type-check to confirm no new cross-file errors were introduced:

```bash
# Type-check the whole project
bun run check

# Or directly via vite-plus
vp check
```

Fix any errors before considering the change done. deps-check tells you **which files to look at**; the type-checker confirms **you got it right** — both steps together close the loop.

## Relationship to Other Mechanisms

- **Type-checking (tsc):** Run `tsc --noEmit` after the change to verify. deps-check is a **pre-change** signal about which files to inspect; tsc is **post-change** verification that you changed them correctly. They complement each other.
- **bug-fix-learning:** If deps-check misses a hidden coupling (e.g. via events or global state), the bug-fix-learning step that follows should record that hidden coupling in the memory or cookbook so future runs can warn about it proactively.
- **code-reviewer:** The review stage will check cross-file impact again, but at that point the changes are already done. deps-check is what lets the review focus on quality rather than regressions.

## Hook Mode (Optional)

You can also attach the script to a PreToolUse hook so it runs automatically before every Edit or Write. Example `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/skills/deps-check/scripts/deps-check.sh \"$CLAUDE_TOOL_INPUT_file_path\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Hook mode suits teams that want the check to run on every edit without exception; skill mode suits individual developers who prefer the AI to judge when it's needed. Both modes use the same underlying script.

## Future Extensions

Only TS/JS is supported today. To add other languages (Python `pydeps`, Go `go list`, etc.), add the corresponding branch in `scripts/deps-check.sh`.
