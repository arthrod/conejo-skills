---
name: conejo-smith
description: Project-local Smith installer. Recommended entry point. Downloads the latest hook scripts, settings fragment, and CLAUDE.md rubric from github.com/arthrod/smith at runtime, copies them into the current repo, then delegates to /smith-speckit for the SpecKit interview — all confined to <project>/.claude/ and the project root. Nothing is written to ~/.claude/. Use when the user wants Smith on a project without polluting their global Claude config, or said "set up smith here", "install smith in this repo", "/conejo-smith", or "bootstrap this project with smith".
argument-hint: [--preset flask-react|fastapi-next|cli-python|express-react] [--no-hooks] [--no-claude-md] [--with-scheduler|--no-scheduler] [--yes] [--ref <commit-or-tag>]
---

# Conejo-Smith — Project-Local Smith Installer

This is the **recommended entry point** for setting up Smith on a project. Acts as a self-contained installer: at invocation time it fetches the latest hook scripts, settings fragment, and rubric from `https://github.com/arthrod/smith`, copies them into `<project>/.claude/` and `<project>/CLAUDE.md`, then delegates to `/smith-speckit` for the full SpecKit interview.

After running, the user's `~/.claude/` directory is unchanged. Everything Smith needs lives under `<project>/.claude/` and `<project>/CLAUDE.md`.

**Arguments:** $ARGUMENTS

---

## Phase 0 — Pre-flight

### 0.1 Resolve source directory

The skill resolves a **source directory** that contains a checkout of the smith repo. Hooks, settings fragment, and rubric template are read from that directory in Phase A.

Resolution order (first match wins):

1. **`$SMITH_SOURCE` env var** (developer/test override) — if set and points to a directory containing both `hooks/` and `settings/smith-settings-fragment-local.json`, use it directly. No clone, no copy.

2. **Network clone** (default) — clone `https://github.com/arthrod/smith` shallowly into a temp dir and use it. Pinnable via `--ref <commit-or-tag>` argument or `$SMITH_REF` env var (default: `main`):

   ```bash
   SMITH_REPO_URL="${SMITH_REPO_URL:-https://github.com/arthrod/smith.git}"
   SMITH_REF="${SMITH_REF:-main}"
   # Honor --ref <X> from $ARGUMENTS if present (overrides $SMITH_REF).
   SOURCE_DIR="$(mktemp -d -t conejo-smith-src.XXXXXX)"
   trap 'rm -rf "$SOURCE_DIR"' EXIT
   git clone --depth 1 --branch "$SMITH_REF" "$SMITH_REPO_URL" "$SOURCE_DIR" \
       || { rm -rf "$SOURCE_DIR"; SOURCE_DIR=""; }
   ```

3. **Bundled fallback** — if the network clone fails AND `~/.claude/skills/conejo-smith/hooks/` was populated by `scripts/install.sh`, use that. The bundle path requires `hooks/`, `settings-fragment.json`, and `claude-md-template.md` to all be present:

   ```bash
   if [ -z "$SOURCE_DIR" ] \
      && [ -d "$HOME/.claude/skills/conejo-smith/hooks" ] \
      && [ -f "$HOME/.claude/skills/conejo-smith/settings-fragment.json" ] \
      && [ -f "$HOME/.claude/skills/conejo-smith/claude-md-template.md" ]; then
       # Treat the bundle as a flattened source layout (no nested settings/ dir).
       SOURCE_DIR="$HOME/.claude/skills/conejo-smith"
       SOURCE_LAYOUT=bundle
   else
       SOURCE_LAYOUT=repo
   fi
   ```

4. **Abort** if neither network nor bundle yields a usable source. The error message MUST mention both reasons (network failure / missing bundle) and suggest one of: a working network connection, `bash scripts/install.sh` to seed the bundle, or `$SMITH_SOURCE=/path/to/local/checkout`.

After resolution, **all reads in Phase A go through `$SOURCE_DIR`**. The two layouts differ in path:

| Asset | repo layout | bundle layout |
|---|---|---|
| Hook scripts | `$SOURCE_DIR/hooks/*.sh` + `*.py` + `pricing.json` | `$SOURCE_DIR/hooks/*` (same) |
| Settings fragment | `$SOURCE_DIR/settings/smith-settings-fragment-local.json` | `$SOURCE_DIR/settings-fragment.json` |
| CLAUDE.md rubric | `$SOURCE_DIR/settings/claude-md-template.md` | `$SOURCE_DIR/claude-md-template.md` |

Compute and remember:

```bash
HOOKS_SRC="$SOURCE_DIR/hooks"
case "$SOURCE_LAYOUT" in
  repo)   FRAGMENT="$SOURCE_DIR/settings/smith-settings-fragment-local.json"
          TEMPLATE="$SOURCE_DIR/settings/claude-md-template.md" ;;
  bundle) FRAGMENT="$SOURCE_DIR/settings-fragment.json"
          TEMPLATE="$SOURCE_DIR/claude-md-template.md" ;;
esac
```

### 0.2 Resolve target directories

- `PROJECT_DIR` = current working directory (the repo to bootstrap into)
- All writes in Phase A go under `$PROJECT_DIR/.claude/` or `$PROJECT_DIR/`
- **Never write outside `$PROJECT_DIR`.** Specifically: do not touch `~/.claude/`, `~/.smith/`, or any ancestor of `$PROJECT_DIR`.

### 0.3 Confirm with the user

Print exactly what will happen, then wait for confirmation (skip the wait if `--yes` is in `$ARGUMENTS`):

```
Conejo-Smith will install everything LOCALLY in this project (~/.claude is NOT touched):

  Source:                                 [repo|bundle] from <github.com/arthrod/smith@<ref>|local bundle>

  PROJECT/.claude/hooks/                  bundled hook scripts (.sh + workflow_summary_lib.py + pricing.json)
  PROJECT/.claude/settings.json           created or merged (hooks + permissions)
  PROJECT/CLAUDE.md                       rubric (existing file backed up)
  PROJECT/.specify/                       constitution + templates + scripts
  PROJECT/.claude/commands/               smith.* slash commands
  PROJECT/.claude/agents/                 review agents (architect, senior-qa, …)
  PROJECT/.smith/vault/                   sessions, agents, queue, bank, ledger
  PROJECT/specs/init-intake.md            permanent record of project answers
  PROJECT/docs/sessions/                  session logs
  PROJECT/.gitignore                      append entries (created if missing)

Proceed? (y/N)
```

Honor `--no-hooks` (skip A.1 + A.2), `--no-claude-md` (skip A.3), and `--with-scheduler` / `--no-scheduler` (force the A.4 decision without prompting; default is to prompt with N as default).

---

## Phase A — Project-local hook & rubric install

This is the part `/smith-speckit` does NOT do. Run these steps before the SpecKit interview.

### A.1 Copy hooks → `PROJECT/.claude/hooks/`

`$HOOKS_SRC` was resolved in Phase 0.1.

```bash
mkdir -p .claude/hooks
# Copy everything: .sh scripts, workflow_summary_lib.py (sourced by
# workflow-summary.sh), and pricing.json. The lib MUST travel with the
# scripts so workflow-summary.sh can locate it via SCRIPT_DIR fallback.
cp "$HOOKS_SRC"/* .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Skip entirely if `--no-hooks` is set. The hook scripts are pure shell and contain no per-project state, so re-running overwrites in place — no backup needed.

### A.2 Merge hook entries into `PROJECT/.claude/settings.json`

The settings fragment uses `${CLAUDE_PROJECT_DIR}/.claude/hooks/...` so hooks resolve to *this* project regardless of cwd inside the repo. `$FRAGMENT` was resolved in Phase 0.1.

```bash
mkdir -p .claude

if [ -f .claude/settings.json ]; then
    cp .claude/settings.json ".claude/settings.json.bak-$(date +%Y%m%d-%H%M%S)"
    jq -s '
      .[0] as $existing | .[1] as $fragment |
      $existing * $fragment |
      .hooks = (
        ($existing.hooks // {}) as $eh |
        ($fragment.hooks // {}) as $fh |
        (($eh | to_entries) + ($fh | to_entries))
        | group_by(.key)
        | map({
            key: .[0].key,
            value: ((map(.value) | add) | unique_by(tojson))
          })
        | from_entries
      )
    ' .claude/settings.json "$FRAGMENT" > .claude/settings.json.tmp
    mv .claude/settings.json.tmp .claude/settings.json
else
    cp "$FRAGMENT" .claude/settings.json
fi
```

Skip entirely if `--no-hooks` is set.

### A.3 Drop global CLAUDE.md rubric

`$TEMPLATE` was resolved in Phase 0.1.

```bash
if [ -f CLAUDE.md ]; then
    cp CLAUDE.md "CLAUDE.md.bak-$(date +%Y%m%d-%H%M%S)"
fi
cp "$TEMPLATE" CLAUDE.md
```

Skip entirely if `--no-claude-md` is set.

> **Note:** Phase B will append project-specific sections (Project Overview, Tech Stack, Common Commands, etc.) to this file. The rubric template is the *baseline*; Phase B appends, it does not overwrite.

### A.4 Optional: enable the global Smith scheduler

The Smith scheduler is a **global, opt-in** macOS LaunchAgent that wakes up once daily at 02:00 and processes tasks tagged `complexity: autonomous` from `.smith/vault/queue/` across **every** project listed in `~/.smith/projects.json`. It is NOT per-project — once enabled it operates over your entire registered project index.

Most users do not need it. Skip if any of the following apply:
- You don't use `/smith-queue add` to defer autonomous tasks
- You're on Linux (LaunchAgent is macOS-only — Linux systemd support not yet available)
- You're unsure

Argument-driven behavior (no prompt fired):
- `--with-scheduler` in `$ARGUMENTS` → install without asking
- `--no-scheduler` in `$ARGUMENTS` → skip without asking
- `--yes` in `$ARGUMENTS` → **does not** auto-confirm the scheduler. The default for this prompt is N; `--yes` only flows through prompts whose default is Y. To install non-interactively, pass `--with-scheduler` explicitly.

Otherwise, detect the current state and prompt:

```bash
PLIST="$HOME/Library/LaunchAgents/com.smith.scheduler.plist"
SCHED_SH="$HOME/.smith/scheduler/smith-scheduler.sh"

# Skip silently if --no-scheduler or platform isn't macOS.
if [[ "$ARGUMENTS" == *"--no-scheduler"* ]] || [[ "$(uname -s)" != "Darwin" ]]; then
    SCHED_DECISION=skip
elif [[ "$ARGUMENTS" == *"--with-scheduler"* ]]; then
    SCHED_DECISION=enable
elif [ -f "$PLIST" ]; then
    # Already enabled — offer disable.
    echo "The Smith scheduler is currently ENABLED ($PLIST)."
    read -r -p "Disable it? (y/N) " reply
    [[ "$reply" =~ ^[yY] ]] && SCHED_DECISION=disable || SCHED_DECISION=skip
else
    # Not enabled — offer enable.
    echo "Smith ships an optional global scheduler — daily 02:00 LaunchAgent that"
    echo "processes autonomous queue tasks across ALL registered projects."
    read -r -p "Enable it? (y/N) " reply
    [[ "$reply" =~ ^[yY] ]] && SCHED_DECISION=enable || SCHED_DECISION=skip
fi
```

If `SCHED_DECISION=enable`:

```bash
mkdir -p "$HOME/.smith/scheduler" "$HOME/Library/LaunchAgents"
cp "$SOURCE_DIR/scheduler/smith-scheduler.sh" "$SCHED_SH"
chmod +x "$SCHED_SH"
sed "s|__SMITH_HOME__|$HOME/.smith|g" \
    "$SOURCE_DIR/scheduler/com.smith.scheduler.plist.template" > "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
echo "✓ Scheduler enabled — daily at 02:00. Disable later by re-running /conejo-smith --no-scheduler … or:"
echo "    launchctl unload \"$PLIST\" && rm -f \"$PLIST\" && rm -rf \"$HOME/.smith/scheduler\""
```

If `SCHED_DECISION=disable`:

```bash
launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$HOME/.smith/scheduler"
echo "✓ Scheduler disabled."
```

If `SCHED_DECISION=skip`: print nothing and continue.

> **Note on bundle layout:** the `$SOURCE_DIR/scheduler/` path above only exists in the `repo` source layout (network clone or `$SMITH_SOURCE` checkout). If `SOURCE_LAYOUT=bundle` (offline fallback), the scheduler files are NOT bundled — `--with-scheduler` should fail with: "Scheduler enable requires the repo source. Re-run with network access or set `$SMITH_SOURCE` to a checkout."

### A.5 Phase A summary

After A.1–A.4, print:

```
Phase A complete:
  ✓ N hook scripts installed in .claude/hooks/        (or "skipped: --no-hooks")
  ✓ .claude/settings.json merged                       (or "skipped: --no-hooks")
  ✓ CLAUDE.md rubric installed (backup: <path>)        (or "skipped: --no-claude-md")
  ✓ Scheduler <enabled|disabled|unchanged>             (decision from A.4)
```

---

## Phase B — Full SpecKit interview & scaffolding

Now run the standard SpecKit-init workflow. It lives at the renamed skill:

```
~/.claude/skills/smith-speckit/SKILL.md
```

Read that file directly and execute its **Phase 1 through Phase 5** verbatim, with the adjustments below. Treat its instructions as inlined here.

### Adjustments vs. `/smith-speckit`

1. **Phase 0 (Locate Skill Assets)** in the smith-speckit SKILL.md — try `~/.claude/skills/smith-speckit/` first (the install.sh-managed copy). If that directory is missing AND the runtime source dir from Phase 0.1 is in `repo` layout, treat `$SOURCE_DIR/skills/smith-speckit/` as the smith-speckit asset root for the duration of Phase B (the freshly-cloned repo carries its own copy). If neither path exists, abort with the same message smith-speckit would print.

2. **Phase 4.3 (Generate CLAUDE.md)** — `CLAUDE.md` already exists from A.3. Do NOT overwrite. Instead, **append** the project-specific sections (Project Overview, Tech Stack, Architecture, SpecKit Workflow, etc.) below the existing rubric content, separated by a clear `\n\n---\n\n` divider and a `# Project-Specific Configuration` heading.

3. **Phase 4.6 (Create `.claude/settings.json`)** — file already exists from A.2. Do NOT overwrite. Instead, **merge** the framework-specific permissions into the existing `permissions.allow` array using jq, deduplicating. Do NOT touch the `hooks` block. Example:

   ```bash
   ADDITIONS='{"permissions":{"allow":["Bash(npm run:*)","Bash(npm install:*)"]}}'
   jq -s '
     .[0] as $existing | .[1] as $additions |
     $existing
     | .permissions.allow = (
         ((.permissions.allow // []) + ($additions.permissions.allow // []))
         | unique
       )
   ' .claude/settings.json <(echo "$ADDITIONS") > .claude/settings.json.tmp
   mv .claude/settings.json.tmp .claude/settings.json
   ```

4. **Phase 5 (Verification report)** — append a "Project-Local Hooks" section to the report listing the hooks now active in `<project>/.claude/hooks/` (count derived from the actual settings fragment) and noting that `~/.claude/` was untouched.

Everything else from the smith SKILL.md (codebase detection, intake document, one-question-at-a-time interview, constitution generation, monorepo handling, command/agent copies, `.gitignore` entries) runs unchanged.

---

## Idempotency

Re-running `/conejo-smith`:

- **Phase A.1**: hooks overwritten in place (pure scripts, no project-specific state).
- **Phase A.2**: existing `settings.json` is backed up first, then merged. Hook entries are deduped by key, so re-running does not duplicate them. Pre-existing user permissions/env are preserved.
- **Phase A.3**: existing `CLAUDE.md` is backed up first, then replaced with the rubric. Phase B then re-appends project sections.
- **Phase B**: reads `specs/init-intake.md` if present and uses recorded answers without re-asking. If the user wants to refresh, they edit the intake file or delete it before re-running.

---

## Why this skill exists (vs. `/smith-speckit`)

| Concern | `/smith-speckit` | `/conejo-smith` |
|---|---|---|
| Hooks | Not installed by this skill — assumes you wired them elsewhere | Installed by the skill, only into the current project |
| `~/.claude/settings.json` | Not touched | Never touched |
| Global `~/.claude/CLAUDE.md` rubric | Not touched | Never touched |
| Project-level `CLAUDE.md` | Created by skill | Created by skill (rubric + project sections) |
| `.specify/`, `.claude/commands/`, vault | Created by skill | Created by skill (delegates to `/smith-speckit`) |
| Scope of effect | Per-project SpecKit only | Per-project: hooks + rubric + SpecKit |

Use `/conejo-smith` for any new project. Use `/smith-speckit` directly only when hooks were already wired by some other path and you only need the SpecKit scaffolding refresh.

---

## Important rules (carry over from `/smith-speckit`)

- **Never modify files in the source skill directory** — read from `~/.claude/skills/conejo-smith/` and `~/.claude/skills/smith-speckit/`, write to `$PROJECT_DIR`.
- **Existing files**: always back up before overwriting (`.bak-YYYYMMDD-HHMMSS` suffix).
- **Minimal questions**: skip any intake question where codebase detection has high confidence. Confirm, don't interrogate.
- **One question at a time** during the Phase 3 interactive walkthrough. No batching.
- **Question files before complex changes**: per `~/.claude/CLAUDE.md` Rule 3, Phase B's interview itself satisfies this — the intake doc IS the question file.
