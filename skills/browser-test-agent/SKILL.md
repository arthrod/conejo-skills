---
name: browser-test-agent
description: Web browser automation & testing for AI agents — agent-browser CLI (Chrome/CDP, fill forms, click, scrape, screenshot, dev-server verification with page-load + console-error + UI-element checks) plus Playwright toolkit for local web apps (debugging UI behavior, browser logs, screenshots). Use when the user asks for web QA, dev-server verification after `npm run dev`, or any browser automation against a website. For desktop/Electron/Tauri apps, see `desktop-test-agent-tauri`.
---

# Browser Test Agent (web)

Two-engine web automation:

| Engine | When |
|---|---|
| **agent-browser** (Rust CLI, Chrome via CDP) | Default. Fast, accessibility-tree snapshots, `@eN` element refs, sessions, auth vault, video recording |
| **Playwright** (webapp-testing toolkit) | When you need Playwright-specific features (multi-context isolation, codegen, video traces) |

## ⚙️ Default Workflow (start here)

When invoked, say:

> "I'll start with the default workflow and assess what stage we're at, then continue from there. If everything is done, I'll come back and ask for your decisions. I can also do A/B/C alternatives — let me know if you want me to lay out capabilities and trade-offs."

The default workflow (run sequentially, wait between steps):

1. **Probe environment** — is the dev server running? `curl http://localhost:3000` or `agent-browser open <url>` with a short timeout.
2. **Capture baseline** — screenshot + console-error dump + interactive-element snapshot.
3. **Run the user's specific test** (or the dev-server-verification checklist below if none specified).
4. **Diagnose failures** with the Browser + Server correlation table.
5. **Iterate** — fix issue, re-run, repeat (max 2 retry cycles).

**Wait between every step** before moving to the next. Don't batch.

### Watching for human comments while waiting

When a step is waiting on the user, a CI run, or any external event, set up a polling watcher so you don't waste tokens spinning:

```bash
# Use the /loop slash-command (Claude Code built-in)
/loop 10m "check for new comments on PR #<N> via gh CLI; if none, re-ping reviewers"

# OR use /schedule for a single delayed wake-up
/schedule "in 20 minutes, re-check comments and continue"
```

Cadence: **start at 10 minutes, back off to 30 minutes** if nothing lands. If 30 minutes pass with no comments, **repeat the request** (re-ping CR, re-ask the user) and continue iterating.

## A / B / C alternative approaches

When the default workflow isn't right, offer:

| Path | Capability | Trade-off |
|---|---|---|
| **A** — agent-browser only | Fast Rust CLI, minimal deps | No multi-context, no codegen |
| **B** — Playwright (webapp-testing) | Codegen, multi-context, video trace, network mocking | Heavier; Node dep; slower startup |
| **C** — Hybrid (agent-browser for the happy path + Playwright for adversarial / multi-tab tests) | Best of both | Two installs, two mental models |

Default to **A** unless the user requests Playwright features or you hit an agent-browser limitation.

---

# agent-browser


# agent-browser

Fast browser automation CLI for AI agents. Chrome/Chromium via CDP with
accessibility-tree snapshots and compact `@eN` element refs.

Install: `npm i -g agent-browser && agent-browser install`

## Start here

This file is a discovery stub, not the usage guide. Before running any
`agent-browser` command, load the actual workflow content from the CLI:

```bash
agent-browser skills get core             # start here — workflows, common patterns, troubleshooting
agent-browser skills get core --full      # include full command reference and templates
```

The CLI serves skill content that always matches the installed version,
so instructions never go stale. The content in this stub cannot change
between releases, which is why it just points at `skills get core`.

## Specialized skills

Load a specialized skill when the task falls outside browser web pages:

```bash
agent-browser skills get electron          # Electron desktop apps (VS Code, Slack, Discord, Figma, ...)
agent-browser skills get slack             # Slack workspace automation
agent-browser skills get dogfood           # Exploratory testing / QA / bug hunts
agent-browser skills get vercel-sandbox    # agent-browser inside Vercel Sandbox microVMs
agent-browser skills get agentcore         # AWS Bedrock AgentCore cloud browsers
```

Run `agent-browser skills list` to see everything available on the
installed version.

## Why agent-browser

- Fast native Rust CLI, not a Node.js wrapper
- Works with any AI agent (Cursor, Claude Code, Codex, Continue, Windsurf, etc.)
- Chrome/Chromium via CDP with no Playwright or Puppeteer dependency
- Accessibility-tree snapshots with element refs for reliable interaction
- Sessions, authentication vault, state persistence, video recording
- Specialized skills for Electron apps, Slack, exploratory testing, cloud providers


# Dev-server verification mode

_(Merged from former agent-browser-verify skill — use when a dev server just started and you want a visual gut-check.)_


# Dev Server Verification with agent-browser

**You MUST verify the dev server with agent-browser after starting it.** Do not assume the page works just because the dev server process started. Many issues (blank pages, hydration errors, missing env vars, broken imports) are only visible in the browser. Run this verification before continuing with any other work:

## Quick Verification Flow

```bash
# 1. Open the dev server
agent-browser open http://localhost:3000
agent-browser wait --load networkidle

# 2. Screenshot for visual check
agent-browser screenshot --annotate

# 3. Check for errors
agent-browser eval 'JSON.stringify(window.__consoleErrors || [])'

# 4. Snapshot interactive elements
agent-browser snapshot -i
```

## Verification Checklist

Run each check and report results:

1. **Page loads** — `agent-browser open` succeeds without timeout
2. **No blank page** — snapshot shows meaningful content (not empty body)
3. **No error overlay** — no Next.js/Vite error overlay detected
4. **Console errors** — evaluate `document.querySelectorAll('[data-nextjs-dialog]')` for error modals
5. **Key elements render** — snapshot `-i` shows expected interactive elements
6. **Navigation works** — if multiple routes exist, verify at least the home route

## Error Detection

```bash
# Check for framework error overlays
agent-browser eval 'document.querySelector("[data-nextjs-dialog], .vite-error-overlay, #webpack-dev-server-client-overlay") ? "ERROR_OVERLAY" : "OK"'

# Check page isn't blank
agent-browser eval 'document.body.innerText.trim().length > 0 ? "HAS_CONTENT" : "BLANK"'
```

## On Failure

If verification fails:

1. Screenshot the error state: `agent-browser screenshot error-state.png`
2. Capture the error overlay text or console output
3. Close the browser: `agent-browser close`
4. Fix the issue in code
5. Re-run verification (max 2 retry cycles to avoid infinite loops)

## Diagnosing a Hanging or Stuck Page

When the page appears stuck (spinner, blank content after load, frozen UI), the browser is only half the story. Correlate what you see in the browser with server-side evidence:

### 1. Capture Browser Evidence

```bash
# Screenshot the stuck state
agent-browser screenshot stuck-state.png

# Check for pending network requests (XHR/fetch that never resolved)
agent-browser eval 'JSON.stringify(performance.getEntriesByType("resource").filter(r => r.duration === 0).map(r => r.name))'

# Check console for errors or warnings
agent-browser eval 'JSON.stringify(window.__consoleErrors || [])'

# Look for fetch calls to workflow/API routes that are pending
agent-browser eval 'document.querySelector("[data-nextjs-dialog]") ? "ERROR_OVERLAY" : "OK"'
```

### 2. Check Server Logs

After capturing browser state, immediately check the backend:

```bash
# Stream Vercel runtime logs for the deployment
vercel logs --follow

# If using Workflow DevKit, check run status
npx workflow inspect runs
npx workflow inspect run <run_id>

# Check workflow health
npx workflow health
```

### 3. Correlate Browser + Server

| Browser Shows | Server Shows | Likely Issue |
|--------------|-------------|-------------|
| Spinner / loading forever | No recent function invocations | API route not being called — check fetch URL in client code |
| Spinner / loading forever | Function started but no step logs | Workflow step is stuck — add `console.log` at step entry/exit |
| Blank page, no errors | Build succeeded, no runtime errors | Hydration issue or missing data — check SSR vs client rendering |
| Network request pending | 504 Gateway Timeout in logs | Function timeout — increase `maxDuration` or optimize step |
| Console: "Failed to fetch" | OIDC/credential error in logs | Missing `vercel env pull` — run `vercel link && vercel env pull` |
| Error overlay visible | Stack trace in runtime logs | Read the server error — it usually has more detail than the client |

### 4. Fix and Re-verify

After fixing the issue:

```bash
# Re-open and verify the fix
agent-browser open http://localhost:3000
agent-browser wait --load networkidle
agent-browser screenshot after-fix.png
agent-browser eval 'document.body.innerText.trim().length > 0 ? "HAS_CONTENT" : "BLANK"'
agent-browser close
```

## On Success

```bash
agent-browser close
```

Report: "Dev server verified — page loads, no errors detected, key UI elements render correctly."

## Suggest Verification After Implementation

When you finish building or implementing a feature (wrote code, created routes, set up a project), briefly let the user know they can ask you to verify everything works with a browser check. One sentence is enough. Don't force it if only a small fix or question was involved.

<!-- cross-ref:start -->

## See also (related skills — Browser / QA family)

If your issue relates to:
- **Playwright toolkit for local web apps** — check `webapp-testing` if appropriate.
- **exploratory testing with full repro evidence** — check `dogfood` if appropriate.
- **agent-browser 0.26.0 Linux workarounds (read before dogfood)** — check `dogfood-quirks` if appropriate.

<!-- cross-ref:end -->


---

# Playwright toolkit (webapp-testing — merged)


# Web Application Testing

To test local web applications, write native Python Playwright scripts.

**Helper Scripts Available**:
- `scripts/with_server.py` - Manages server lifecycle (supports multiple servers)

**Always run scripts with `--help` first** to see usage. DO NOT read the source until you try running the script first and find that a customized solution is abslutely necessary. These scripts can be very large and thus pollute your context window. They exist to be called directly as black-box scripts rather than ingested into your context window.

## Decision Tree: Choosing Your Approach

```
User task → Is it static HTML?
    ├─ Yes → Read HTML file directly to identify selectors
    │         ├─ Success → Write Playwright script using selectors
    │         └─ Fails/Incomplete → Treat as dynamic (below)
    │
    └─ No (dynamic webapp) → Is the server already running?
        ├─ No → Run: python scripts/with_server.py --help
        │        Then use the helper + write simplified Playwright script
        │
        └─ Yes → Reconnaissance-then-action:
            1. Navigate and wait for networkidle
            2. Take screenshot or inspect DOM
            3. Identify selectors from rendered state
            4. Execute actions with discovered selectors
```

## Example: Using with_server.py

To start a server, run `--help` first, then use the helper:

**Single server:**
```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_automation.py
```

**Multiple servers (e.g., backend + frontend):**
```bash
python scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python your_automation.py
```

To create an automation script, include only Playwright logic (servers are managed automatically):
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True) # Always launch chromium in headless mode
    page = browser.new_page()
    page.goto('http://localhost:5173') # Server already running and ready
    page.wait_for_load_state('networkidle') # CRITICAL: Wait for JS to execute
    # ... your automation logic
    browser.close()
```

## Reconnaissance-Then-Action Pattern

1. **Inspect rendered DOM**:
   ```python
   page.screenshot(path='/tmp/inspect.png', full_page=True)
   content = page.content()
   page.locator('button').all()
   ```

2. **Identify selectors** from inspection results

3. **Execute actions** using discovered selectors

## Common Pitfall

❌ **Don't** inspect the DOM before waiting for `networkidle` on dynamic apps
✅ **Do** wait for `page.wait_for_load_state('networkidle')` before inspection

## Best Practices

- **Use bundled scripts as black boxes** - To accomplish a task, consider whether one of the scripts available in `scripts/` can help. These scripts handle common, complex workflows reliably without cluttering the context window. Use `--help` to see usage, then invoke directly. 
- Use `sync_playwright()` for synchronous scripts
- Always close the browser when done
- Use descriptive selectors: `text=`, `role=`, CSS selectors, or IDs
- Add appropriate waits: `page.wait_for_selector()` or `page.wait_for_timeout()`

## Reference Files

- **examples/** - Examples showing common patterns:
  - `element_discovery.py` - Discovering buttons, links, and inputs on a page
  - `static_html_automation.py` - Using file:// URLs for local HTML
  - `console_logging.py` - Capturing console logs during automation

<!-- cross-ref:start -->

## See also (related skills — Browser / QA family)

If your issue relates to:
- **browser automation CLI (general + dev-server verify)** — check `agent-browser` if appropriate.
- **exploratory testing with full repro evidence** — check `dogfood` if appropriate.
- **agent-browser 0.26.0 Linux workarounds (read before dogfood)** — check `dogfood-quirks` if appropriate.

<!-- cross-ref:end -->

