---
name: dogfood-quirks
description: Workarounds for agent-browser version 0.26.0 quirks on Linux (sandbox launch failure, broken --timeout, silent stale refs, find-role syntax). Read BEFORE invoking the /dogfood skill or running any agent-browser command. Otherwise: Chrome won't launch, refs will silently click the wrong element, waits will take 30s instead of 3s.
---

# dogfood-quirks

The `agent-browser` CLI's own help and its bundled `skills get core` documentation disagree with the binary's actual behavior in several places. This skill is the empirical truth list. Apply before any `/dogfood` flow.

Tested against agent-browser **0.26.0** on Linux 6.8 (Ubuntu 23.10+) in May 2026. Re-validate if the major version changes — quirks 1, 3, 4 may be patched upstream.

## Required setup (every shell session)

```bash
export AGENT_BROWSER_ARGS="--no-sandbox"
export AGENT_BROWSER_DEFAULT_TIMEOUT=10000
```

Skip this and Chrome will not launch, waits will take 30s instead of your requested timeout. Both must be `export`-ed before any `agent-browser` invocation — the daemon reads them at launch time and inline `--args` is silently ignored if a daemon is already running.

## Error → fix lookup

When you see this in stderr, apply this fix and retry:

| Error message | Fix |
|---|---|
| `✗ Auto-launch failed: Chrome exited early ... No usable sandbox!` | `export AGENT_BROWSER_ARGS="--no-sandbox"` then `agent-browser close --all` then retry |
| `⚠ --args ignored: daemon already running` | `agent-browser close --all`, set the env var, retry. `--args` only works on first launch |
| `✗ Failed to save screenshot to /path: No such file or directory (os error 2)` | `mkdir -p $(dirname "$path")` first. Screenshot never creates parent dirs |
| `✗ Wait timed out after 30000ms` (you set `--timeout 3000`) | `--timeout` flag is broken. Set `AGENT_BROWSER_DEFAULT_TIMEOUT` globally instead |
| `✗ Unknown subaction: --name` (using `find role X click --name Y`) | Documented syntax is broken. Use `find text "Y" click` instead |
| `✓ Done` after a `click @e1` on a page you just navigated to | Stale ref silently clicked the new `@e1`. Always re-`snapshot -i` after navigation |
| `snapshot -i` first element is `[generic] "((e,t,n,r,..."` script source | Theme-bootstrap script appears as `@e1` noise. Look for real content at `@e2`+, or scope: `snapshot -i -s "#main"` |
| `errors` or `console` returns empty output | Could be "no events" OR "command failed". Check `$?` — it's the only signal |

## The eight confirmed quirks

### 1. Chrome won't launch without `--no-sandbox` on Linux 23.10+

Root cause: AppArmor disables unprivileged user namespaces. The skill docs hint at `--args "--no-sandbox"` but that flag is ignored on every launch after the first daemon. Use the env var:

```bash
export AGENT_BROWSER_ARGS="--no-sandbox"
```

This persists for all subsequent daemon launches in the shell. Verify:
```bash
agent-browser --session test open https://example.com
# Should succeed with: ✓ ... https://example.com/
```

### 2. Screenshot never creates parent directories

`agent-browser screenshot /tmp/x/y/shot.png` fails with `os error 2` if `/tmp/x/y/` doesn't exist. There is no `--create-dirs` flag. Always:

```bash
SCREENSHOT_DIR=/tmp/my-dogfood/screenshots
mkdir -p "$SCREENSHOT_DIR"
agent-browser screenshot "$SCREENSHOT_DIR/shot.png"
```

The `/dogfood` skill template does this in its init step — preserve that pattern.

### 3. `wait --timeout N` is broken; silently uses 25s global default

```bash
agent-browser wait "#nonexistent" --timeout 3000   # actually waits 30s, not 3s
```

There is no working per-command timeout flag. Use the global env var:

```bash
export AGENT_BROWSER_DEFAULT_TIMEOUT=10000   # 10s default for ALL commands
```

For a truly dumb sleep, use a positional ms wait (`agent-browser wait 2000`) — but that's an unconditional sleep, not a "wait for X" with a deadline.

### 4. `find role X click --name "Y"` is broken; use `find text` or refs

The skill docs and inline help both show:

```bash
agent-browser find role button click --name "Submit"  # documented, BROKEN
```

The binary rejects this with `✗ Unknown subaction: --name`. Working alternatives:

```bash
agent-browser find text "Submit" click             # ✓
agent-browser find text "Submit" click --exact     # ✓
agent-browser find label "Email" fill "..."        # ✓
agent-browser find placeholder "Search" type "..." # ✓
agent-browser find testid "submit-btn" click       # ✓
```

Best practice: prefer `snapshot -i` + refs (`@e3`). `find text` is the next-best escape hatch.

### 5. Stale refs DO NOT throw — they silently click the wrong element

After ANY navigation, form submit, modal open/close, or dynamic re-render, refs are reassigned by DOM order. Old `@e1` becomes whatever is now first. The CLI returns `✓ Done` against the new element with no warning.

**Always re-snapshot after any page-changing action.** The `&&` chaining pattern from the docs requires this:

```bash
# WRONG — @e6 might be a different element on /sign-in
agent-browser open https://app.com && \
  agent-browser snapshot -i && \
  agent-browser click @e6 && \
  agent-browser click @e8   # ← @e8 may now mean something else

# RIGHT — re-snapshot after navigation
agent-browser open https://app.com && agent-browser snapshot -i
agent-browser click @e6              # navigates to /sign-in
agent-browser snapshot -i            # refs reassigned
agent-browser click @e8              # safe — @e8 is from the new snapshot
```

### 6. Snapshot starts with theme-bootstrap script as `@e1` noise

Output:
```
- generic "((e,t,n,r,i,a,o,s)=>{let c=document.documentElement,..." [ref=e1] clickable [onclick]
  - link "Sign in" [ref=e6]
  - ...
```

The first `@e1 [generic] clickable` is the dark-mode bootstrap inline script being rendered as the top-level clickable element. Real content starts at `@e2`+. Two coping strategies:

```bash
# Strategy A — scope snapshot to a CSS selector
agent-browser snapshot -i -s "#main"

# Strategy B — JSON output + jq filter
agent-browser snapshot -i --json | jq '.data.refs | to_entries | map(select(.value.role != "generic"))'
```

### 7. `errors` and `console` return empty for BOTH "clean" and "failed"

```bash
agent-browser errors    # no output — could mean: (a) zero errors, OR (b) command failed
```

Exit code is the only signal. Check `$?`:

```bash
agent-browser errors
if [ $? -ne 0 ]; then echo "errors command failed"; else echo "no errors found"; fi
```

For a positive "page is clean" signal, prefer evaluating page state directly:

```bash
agent-browser eval --stdin <<'EOF'
({
  errorCount: window.__cicero_errors?.length ?? 0,
  url: location.href,
  title: document.title
})
EOF
```

### 8. `state save` dumps ALL cookies, including cross-site

The daemon's Chrome profile accumulates cookies from every domain visited in any session. `state save my.json` writes them all — including Google login tokens, Cloudflare, anything else. For per-test isolated auth state:

```bash
# Use --profile to isolate; each path is its own Chrome profile
agent-browser --profile /tmp/profiles/alice --session alice open https://app.com
agent-browser --profile /tmp/profiles/alice --session alice state save /tmp/alice-auth.json
# alice-auth.json contains only what /tmp/profiles/alice accumulated
```

NEVER commit state files. They contain session tokens in plaintext. Add `*-state.json`, `auth-*.json`, `cookies*.txt` to `.gitignore` before saving anything.

## Reliable patterns

### Pattern: single-task dogfood

```bash
export AGENT_BROWSER_ARGS="--no-sandbox"
export AGENT_BROWSER_DEFAULT_TIMEOUT=10000
SESSION="dogfood-$(date +%s)"
OUT="/tmp/$SESSION"
mkdir -p "$OUT/screenshots" "$OUT/videos"

agent-browser --session "$SESSION" open https://app.example.com
agent-browser --session "$SESSION" wait --load networkidle
agent-browser --session "$SESSION" snapshot -i
agent-browser --session "$SESSION" screenshot "$OUT/screenshots/landing.png"
# ... interact ...
agent-browser --session "$SESSION" close
```

### Pattern: sign-in with re-snapshot discipline

```bash
agent-browser --session "$S" open https://app.example.com/sign-in
agent-browser --session "$S" wait --load networkidle
agent-browser --session "$S" snapshot -i   # find email/password/submit refs
agent-browser --session "$S" fill @e4 "$EMAIL"
agent-browser --session "$S" fill @e8 "$PASSWORD"
agent-browser --session "$S" click @e6
agent-browser --session "$S" wait --url "**/dashboard"
agent-browser --session "$S" snapshot -i   # refs are now from /dashboard
agent-browser --session "$S" state save "$OUT/auth.json"
```

### Pattern: repro video for an interactive bug

```bash
mkdir -p "$OUT/videos"
agent-browser --session "$S" record start "$OUT/videos/issue-001.webm"

agent-browser --session "$S" screenshot "$OUT/screenshots/issue-001-step-1.png"
sleep 1
agent-browser --session "$S" click @e3
sleep 1
agent-browser --session "$S" snapshot -i   # post-click state
agent-browser --session "$S" screenshot "$OUT/screenshots/issue-001-step-2.png"
sleep 2
agent-browser --session "$S" screenshot --annotate "$OUT/screenshots/issue-001-result.png"

agent-browser --session "$S" record stop
```

`sleep 1` between actions and `sleep 2` before the final shot — videos need to be watchable at 1× by a human reviewer.

### Pattern: cleanup discipline

After any dogfood task:

```bash
agent-browser close --all    # close every session daemon
```

Daemons that linger waste memory and can interfere with the next session if a name is reused. They also accumulate Chrome processes over a long working session.

Periodic deeper cleanup:

```bash
agent-browser state clean --older-than 30    # auto-delete state files >30d
agent-browser doctor --fix                   # destructive repairs (reinstall Chrome, purge stale sockets)
```

## The 100-tool-call ceiling (forge dispatches)

When dispatched via `forge` with a per-turn tool-call limit, an interactive dogfood will exhaust the budget. Mitigations:

- **Split per-role**: 3 forges, one role each
- **Pre-can the auth state**: save `auth.json` outside the forge; pass via `--state`
- **Skip forge entirely**: invoke the `/dogfood` skill from the local Claude/CC session, which doesn't have the per-turn cap

If a forge dies mid-dogfood, the partial findings ARE preserved in `$OUT/report.md` — pick up where it left off in a fresh forge.

## Vision-augmented dogfood (the canonical recipe)

agent-browser sees pixels; deepseek can't. When a dogfood needs visual reasoning ("does this look right?", "what's the visual hierarchy?", "is that button obscured?"), pair agent-browser with a vision-capable model via opencode.

**Pattern: agent-browser shoots → opencode + Gemini reads.**

```bash
SESSION="my-dogfood"
OUT="/tmp/$SESSION"
mkdir -p "$OUT/screenshots"

# 1. Shoot
agent-browser --session "$SESSION" open https://app.example.com
agent-browser --session "$SESSION" wait --load networkidle
agent-browser --session "$SESSION" screenshot "$OUT/screenshots/landing.png"

# 2. Read (with Gemini 3.1 Pro Preview — vision-capable)
opencode run \
  --model google/gemini-3.1-pro-preview \
  --dangerously-skip-permissions \
  "Describe the visual hierarchy of this landing page. Identify the primary CTA, the secondary CTA, and any decorative-only elements. Note color contrast issues and visual-weight imbalances." \
  -f "$OUT/screenshots/landing.png"
```

**Critical: `-f <file>` must come AFTER the message string.** opencode parses `-f` greedily — if you put it before the prompt, the prompt itself is treated as another file and opencode dies with `File not found: <your prompt text>`.

Multiple images per call work:
```bash
opencode run --model google/gemini-3.1-pro-preview --dangerously-skip-permissions \
  "Compare these two screenshots. The first is /admin landing for a member; the second is for an admin. What's the delta?" \
  -f "$OUT/member.png" -f "$OUT/admin.png"
```

**Model slugs** (tested via `opencode models | grep gemini-3.1-pro`):
- `google/gemini-3.1-pro-preview` — direct Google, recommended
- `opencode/gemini-3.1-pro` — opencode's own routing
- `github-copilot/gemini-3.1-pro-preview` — via Copilot
- `zenmux/google/gemini-3.1-pro-preview` — via zenmux

For Sonnet vision: `anthropic/claude-sonnet-4.6`. For GPT-4o: `openai/gpt-4o`.

### Why NOT `agent-browser chat`

agent-browser has a `chat` subcommand that uses Vercel AI Gateway (`AI_GATEWAY_API_KEY`) to drive itself via natural language. It works, but:

- Requires a Vercel AI Gateway API key (new dependency)
- Couples the vision model to the browser tool — harder to swap
- The `chat` REPL pattern is less reviewable than discrete shoot+read steps

The shoot+read pattern keeps the human/agent in control of what's captured and what's asked. Save `chat` for autonomous-exploration scenarios where you don't know what to capture in advance.

## When NOT to use this

If your task is a code-walkthrough or static analysis ("does this PR's claim match the code?"), use `opencode` directly against the repo — no browser needed. Reading code is cheaper, faster, and skips all of these browser quirks. agent-browser is for live HTTP + visual verification only.

<!-- cross-ref:start -->

## See also (related skills — Browser / QA family)

If your issue relates to:
- **browser automation CLI (general + dev-server verify)** — check `agent-browser` if appropriate.
- **Playwright toolkit for local web apps** — check `webapp-testing` if appropriate.
- **exploratory testing with full repro evidence** — check `dogfood` if appropriate.

<!-- cross-ref:end -->

