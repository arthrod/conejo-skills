---
name: desktop-test-agent-tauri
description: Desktop & Tauri app testing for AI agents — Tauri v2 + WebKitGTK in Docker (AppImage extraction, Gemini Computer Use, virtual display, DOCX export verification) plus Electron app automation (VS Code, Slack, Discord, Figma) via `agent-browser skills get electron`. Use when testing a Tauri desktop app (Cicero), Electron app, or any non-browser desktop UI. For web browser testing, see `browser-test-agent`.
---

# Desktop Test Agent (Tauri / Electron)

Two desktop surfaces:

| Engine | When |
|---|---|
| **tauri-docker-testing** | Cicero Tauri app in Docker — AppImage extraction, WebKitGTK virtual display, Gemini Computer Use automation, DOCX export verification |
| **agent-browser electron subcommand** | Electron desktop apps via `agent-browser skills get electron` (VS Code, Slack, Discord, Figma, Notion, Spotify) |

## ⚙️ Default Workflow (start here)

When invoked, say:

> "I'll start with the default workflow and assess what stage we're at, then continue from there. If everything is done, I'll come back and ask for your decisions. I can also do A/B/C alternatives — let me know if you want me to lay out capabilities and trade-offs."

Default flow for a Tauri/Electron app:

1. **Probe the build** — does the AppImage / Electron binary exist and launch?
2. **Set up environment** — virtual display (Xvfb), required system packages, env vars.
3. **Launch the app** under instrumentation (Gemini Computer Use or agent-browser CDP).
4. **Capture baseline** — screenshot of initial window, log dump.
5. **Run the user's specific check** (or "does the export feature work end-to-end" if none specified).
6. **Diagnose** — distinguish app crashes vs WebKitGTK issues vs missing system deps.
7. **Iterate** — fix and re-run (max 2 retry cycles).

**Wait between every step** before moving to the next. Don't batch.

### Watching for human comments while waiting

When a step is waiting on the user, a CI run, or any external event, set up a polling watcher:

```bash
/loop 10m "check for new comments on PR #<N> via gh CLI; if none, re-ping reviewers"
/schedule "in 20 minutes, re-check comments and continue"
```

Cadence: **start at 10 minutes, back off to 30 minutes** if nothing lands. If 30 minutes pass with no comments, **repeat the request** (re-ping CR, re-ask the user) and continue iterating.

## A / B / C alternative approaches

| Path | Capability | Trade-off |
|---|---|---|
| **A** — Docker + Xvfb + Gemini Computer Use | Fully reproducible CI; works on headless Linux | Slow startup; Gemini token cost |
| **B** — Local native execution + agent-browser CDP | Fastest iteration; uses real Chrome of the app | Only works on a graphical session; OS-specific |
| **C** — Manual screenshot + visual diff | Lowest infra cost | Brittle; doesn't catch interaction bugs |

Default to **A** for Cicero Tauri (Docker-reproducible), **B** for Electron apps you're developing locally.

---

# Tauri Docker Testing


# Tauri Docker Testing

Test Cicero's Tauri AppImage inside a Docker container with virtual display and **Gemini Computer Use** for vision-driven UI automation.

## Step-by-Step: The Full Pipeline

Follow these steps IN ORDER. Every command is copy-pasteable. Do NOT skip steps.

### STEP 1: Build the AppImage

```bash
cd /home/arthrod/workspace/potion_deploy
git checkout main && git pull
```

Build the Vite frontend first (REQUIRED before cargo build):
```bash
NODE_ENV=production VITE_ENVIRONMENT=production bun run build:tauri
```

Then build the Tauri AppImage:
```bash
cd src-tauri && cargo tauri build --bundles appimage
```

Output will be at: `src-tauri/target/release/bundle/appimage/Cicero_0.1.0_amd64.AppImage` (~83MB)

**If cargo build fails with "beforeBuildCommand" error:** The Vite build above didn't run. Run it again.

### STEP 2: Build the Docker Image

```bash
cd /home/arthrod/workspace/potion_deploy
docker build -t cicero-test -f Dockerfile.computer-use .
```

**If "no such file" error:** You're in the wrong directory. `cd` to the repo root.

**What the Dockerfile does:**
- Installs Ubuntu 24.04 + Xvfb + VNC + noVNC + Chromium + WebKitGTK deps
- Copies the AppImage into `/app/`
- Extracts it with `--appimage-extract` (FUSE doesn't work in Docker — never try to run the AppImage directly)
- Registers `cicero://` deep link scheme via xdg-mime
- Sets up supervisor to manage Xvfb, fluxbox, x11vnc, noVNC, dbus, and the Cicero app

### STEP 3: Start the Container

```bash
docker rm -f cicero-test 2>/dev/null
docker run -d --name cicero-test -p 5901:5900 -p 6081:6080 --shm-size=1g cicero-test
```

**Port 5900 in use?** That's why we use 5901:5900. If 5901 is also taken, use any free port.

**`--shm-size=1g` is REQUIRED.** Without it, Chromium crashes with "insufficient shared memory".

### STEP 4: Wait for the App to Load

The app takes ~15-30 seconds to start. Supervisor will show `cicero (exit status 101)` warnings — **THIS IS NORMAL**. The app crashes 2-4 times because Xvfb/dbus aren't ready yet. Supervisor retries and it eventually starts.

```bash
sleep 30
```

Check if the app is running:
```bash
docker exec cicero-test ps aux | grep cicero_desktop
```

You should see `cicero_desktop` in the process list. If not, start it manually:
```bash
docker exec -d -e DISPLAY=:99 -e DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-session \
  -e XDG_RUNTIME_DIR=/tmp/runtime-agent -e NO_AT_BRIDGE=1 \
  -e WEBKIT_DISABLE_DMABUF_RENDERER=1 -u agent cicero-test /app/cicero/AppRun
sleep 15
```

**ALL of these env vars are REQUIRED:**
- `DISPLAY=:99` — virtual display
- `DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-session` — WebKitGTK needs dbus
- `XDG_RUNTIME_DIR=/tmp/runtime-agent` — XDG runtime
- `NO_AT_BRIDGE=1` — suppress accessibility warnings
- `WEBKIT_DISABLE_DMABUF_RENDERER=1` — **CRITICAL: without this, the app crashes with GPU/DMA errors**

### STEP 5: Close WebKit Inspector (CRITICAL)

**THE APP OPENS WEBKIT INSPECTOR BY DEFAULT.** Inspector steals ALL keyboard focus. If you skip this step, `xdotool type` and Gemini Computer Use typing will go to the inspector console, NOT the app.

```bash
docker exec -e DISPLAY=:99 -u agent cicero-test xdotool key F12
sleep 1
```

### STEP 6: Take a Screenshot to Verify

```bash
docker exec -e DISPLAY=:99 -u agent cicero-test scrot /tmp/verify.png
docker cp cicero-test:/tmp/verify.png ./verify.png
```

You should see the Cicero sign-in page: "Contracts from the future" on the left, email/password form on the right.

**If you see a blank/gray desktop:** The app didn't start. Go back to Step 4 and start manually.

**If you see the WebKit Inspector taking up half the screen:** Go back to Step 5.

### STEP 7: Run Gemini Computer Use Agent

This is the main automation tool. It takes screenshots, sends them to Gemini, and executes the model's actions via xdotool.

**Prerequisites:**
- `google-genai` Python package: `uv pip install google-genai` (or `pip install google-genai`)
- `GEMINI_API_KEY` env var set

```bash
GEMINI_API_KEY=$GEMINI_API_KEY python3 tooling/scripts/tauri-computer-use.py \
  --container cicero-test \
  --goal "Create a new account with email test@cicero.im, password TDDisthesolution, first name Test, last name User. After login, click the WRITE card to create a document. Type a haiku in the editor. Then export as DOCX." \
  --model gemini-3-flash-preview \
  --max-turns 20
```

**The agent will:**
1. Find the Sign Up link and click it
2. Fill in the sign-up form fields
3. Accept terms and submit
4. Click the WRITE card on the dashboard
5. Type text in the editor
6. Find the export button and trigger DOCX download
7. Handle the GTK save dialog

**If the agent gets stuck in a safety confirmation loop:** The Gemini CU model keeps asking for confirmation on downloads. The script auto-confirms, but sometimes the model loops. Kill it (Ctrl+C) and handle the remaining steps manually.

**If `response.candidates` is None:** Safety block from Gemini. The script handles this gracefully and retries.

### STEP 8: Manual Typing Fallback

If the Computer Use agent can't type in the Plate editor (text doesn't appear), do it manually:

```bash
# MUST close inspector first (Step 5)
docker exec -e DISPLAY=:99 -u agent cicero-test bash -c "
xdotool mousemove 600 300 && sleep 0.3 && xdotool click 1 && sleep 0.5
xdotool type --delay 30 'Contracts from the past'
xdotool key Return
xdotool type --delay 30 'AI writes the future now'
xdotool key Return
xdotool type --delay 30 'Cicero guides all'
"
```

**MUST use `xdotool type --delay 30 'text'`.** Individual `xdotool key X` calls do NOT trigger Slate/Plate input events. The `type` command fires the proper IME/input pipeline that Plate.js listens to.

**`xdotool type` mangles uppercase** — it uses `--clearmodifiers` which strips Shift. "AI" becomes "ai", "Cicero" becomes "cicero". This is cosmetic and acceptable for testing.

### STEP 9: DOCX Export

After typing content in the editor:

1. Use the Computer Use agent to click the export button:
```bash
GEMINI_API_KEY=$GEMINI_API_KEY python3 tooling/scripts/tauri-computer-use.py \
  --container cicero-test \
  --goal "Click the export/download icon in the toolbar and export as DOCX" \
  --model gemini-3-flash-preview \
  --max-turns 5
```

2. If the agent gets stuck, do it manually — the export flow is:
   - Click export icon in toolbar → "Download" dialog appears (format: WORD)
   - Click red "Download" button → "Export to DOCX" confirmation dialog
   - Click red "Continue" button → GTK "Save File" dialog
   - Press Enter to save with default filename

3. Check if the DOCX was saved:
```bash
docker exec cicero-test find / -name "*.docx" -type f 2>/dev/null
```

4. Copy it out:
```bash
docker cp cicero-test:/path/to/file.docx ./output.docx
```

5. Verify it's valid:
```bash
python3 -c "
import zipfile, re
z = zipfile.ZipFile('./output.docx')
doc = z.read('word/document.xml').decode('utf-8')
texts = re.findall(r'<w:t[^>]*>([^<]+)</w:t>', doc)
for t in texts: print(t)
"
```

**If DOCX export fails (yellow warning in Download dialog):**
- Check `fs:allow-write-file` is in `src-tauri/capabilities/default.json`
- Without this permission, the GTK save dialog appears but `writeFile()` silently fails
- This was the bug we found — `fs:default` only grants READ, not write

### STEP 10: Verify & Clean Up

Take final screenshot:
```bash
docker exec -e DISPLAY=:99 -u agent cicero-test scrot /tmp/final.png
docker cp cicero-test:/tmp/final.png ./final.png
```

Stop container:
```bash
docker rm -f cicero-test
```

## Gemini Computer Use: How `tauri-computer-use.py` Works

### Architecture

```
Host machine                          Docker container (Ubuntu 24.04)
┌──────────────────┐                  ┌─────────────────────────────┐
│ tauri-computer-   │  docker exec    │ Xvfb :99 (virtual display)  │
│ use.py            │ ──────────────> │ Cicero AppImage (WebKitGTK) │
│                   │  scrot → PNG    │ x11vnc (VNC on :5900)       │
│ Gemini CU API    │ <────────────── │ noVNC (web on :6080)        │
│ (google-genai)   │  xdotool cmds   │ fluxbox (window manager)    │
│                   │ ──────────────> │ dbus-daemon                 │
└──────────────────┘                  └─────────────────────────────┘
```

### Agent Loop

1. Takes screenshot from Docker via `docker exec scrot`
2. Sends screenshot + goal to Gemini Computer Use API (native `google-genai` SDK)
3. Model returns `function_call` actions with normalized coordinates (0-999)
4. Script denormalizes: `actual_x = x / 1000 * 1440`, `actual_y = y / 1000 * 960`
5. Executes via `xdotool` (click, type, scroll, key combos)
6. Takes new screenshot, sends back as `FunctionResponse` with:
   - `url`: `"cicero://localhost"` (REQUIRED — 400 error without it)
   - `safety_acknowledgement`: `"true"` (REQUIRED when model sends `require_confirmation`)
   - Screenshot as `FunctionResponsePart` with `inline_data` blob
7. Loop until model says done or max turns reached

### Supported Gemini Models

| Model | Use Case |
|-------|----------|
| `gemini-3-flash-preview` | Fast, good for most tasks |
| `gemini-2.5-computer-use-preview-10-2025` | Dedicated CU model, more accurate |

### What DOESN'T Work for Automation

| Approach | Why It Fails | What Happens |
|----------|-------------|-------------|
| **Midscene** | Uses OpenAI-compatible endpoint (`/v1beta/openai/`) which does NOT support Computer Use | Returns "empty content from AI model" on every Gemini model |
| **agent-browser via noVNC** | VNC canvas is a single `<canvas>` element | agent-browser sees noVNC controls (disconnect, clipboard) but NOT the app UI inside |
| **xdotool coordinate guessing** | No vision — you're guessing pixel positions | Breaks when layout changes, wastes time iterating |
| **`xdotool key` per character** | Individual key events don't trigger Slate/Plate input | Text never appears in the editor contenteditable |

## Dockerfile Requirements

`Dockerfile.computer-use` must include ALL of these:

```dockerfile
RUN apt-get install -y \
    # Virtual display + window manager
    xvfb fluxbox xterm \
    # VNC + noVNC (browser-based VNC viewer)
    x11vnc novnc websockify \
    # OAuth browser (for Google OAuth roundtrip)
    chromium-browser \
    # WebKitGTK — Tauri's Linux rendering engine
    libwebkit2gtk-4.1-0 libgtk-3-0t64 \
    libappindicator3-1 librsvg2-2 libsoup-3.0-0 \
    # D-Bus + Accessibility (WebKitGTK REFUSES to start without dbus)
    dbus-x11 at-spi2-core libatk-bridge2.0-0 libatspi2.0-0 \
    # AppImage extraction (FUSE doesn't work in Docker)
    libfuse2t64 \
    # UI automation tools
    scrot xdotool wmctrl \
    # Deep link registration (cicero:// scheme)
    xdg-utils desktop-file-utils \
    # Midscene deps (if you want to try Midscene — it won't work for CU but connect/screenshot work)
    nodejs npm imagemagick x11-xserver-utils \
    # Process manager
    supervisor \
    # Fonts (without these, screenshots show boxes instead of text)
    fonts-liberation fonts-noto-color-emoji fonts-dejavu \
    # Misc
    curl ca-certificates
```

### Deep Link Registration

Register `cicero://` so OAuth deep links work:

```dockerfile
RUN cat > /usr/share/applications/cicero-handler.desktop << 'EOF'
[Desktop Entry]
Name=Cicero Deep Link Handler
Exec=/app/cicero/AppRun %u
Type=Application
MimeType=x-scheme-handler/cicero;
NoDisplay=true
EOF
RUN update-desktop-database /usr/share/applications/
```

### Supervisor Config

```ini
[program:cicero]
command=/app/cicero/AppRun
environment=DISPLAY=":99",DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session",XDG_RUNTIME_DIR="/tmp/runtime-agent",NO_AT_BRIDGE="1",WEBKIT_DISABLE_DMABUF_RENDERER="1"
autorestart=true
user=agent
priority=40
startsecs=5
startretries=10
```

`startretries=10` because the app crashes on startup until Xvfb is ready. `startsecs=5` gives it time to actually initialize.

## Tauri Capabilities (Permissions)

File: `src-tauri/capabilities/default.json`

These permissions MUST be present:

```json
{
  "permissions": [
    "core:default",
    "deep-link:default",
    "dialog:default",
    "fs:default",
    "fs:allow-write-file",
    "fs:allow-write-text-file",
    "http:default",
    "opener:default",
    "os:default",
    "sql:default",
    "sql:allow-execute",
    "clipboard-manager:default",
    "notification:default",
    "store:default",
    "upload:default",
    "websocket:default"
  ]
}
```

**`fs:allow-write-file` is CRITICAL.** Without it:
- The GTK "Save File" dialog appears (from `@tauri-apps/plugin-dialog save()`)
- User picks a filename and clicks Save
- `@tauri-apps/plugin-fs writeFile()` silently fails — no error, no file
- The DOCX export appears to work but the file is never written

**ALL app methods are CLIENT-SIDE.** DOCX export, file save, clipboard, notifications — these all use Tauri plugins (`@tauri-apps/plugin-fs`, `@tauri-apps/plugin-dialog`). They do NOT depend on Cloudflare Worker bindings. The server only provides auth, document CRUD, and AI endpoints.

## All Known Pitfalls (Complete List)

| # | Pitfall | Symptom | Fix |
|---|---------|---------|-----|
| 1 | WebKit Inspector open | Typing goes to console, not editor | Press F12 before any text input |
| 2 | Missing `WEBKIT_DISABLE_DMABUF_RENDERER=1` | App crashes immediately with GPU error | Add to env vars in supervisor and manual start |
| 3 | Missing `dbus-x11` package | WebKitGTK refuses to start, exit 101 | Install in Dockerfile |
| 4 | AppImage run directly (not extracted) | "FUSE not available" error | Always `--appimage-extract` first |
| 5 | `fs:default` without `fs:allow-write-file` | DOCX save dialog works but file never writes | Add `fs:allow-write-file` to capabilities |
| 6 | `xdotool key` per character in Plate | Text never appears in editor | Use `xdotool type --delay 30 'text'` |
| 7 | Port 5900 already in use | Container fails to start | Use `-p 5901:5900 -p 6081:6080` |
| 8 | Missing `--shm-size=1g` | Chromium crashes | Add to `docker run` |
| 9 | Supervisor gives up on cicero | `FATAL state, too many retries` | Increase `startretries=10` or start manually |
| 10 | Midscene for computer use | "empty content from AI model" | Use `tauri-computer-use.py` with native Gemini CU API |
| 11 | agent-browser via noVNC | Can only see canvas, not app UI | Use Gemini CU or direct xdotool |
| 12 | Missing `safety_acknowledgement` in CU response | Gemini returns 400 INVALID_ARGUMENT | Add `"safety_acknowledgement": "true"` to FunctionResponse |
| 13 | `response.candidates` is None | Safety block or rate limit | Handle gracefully, retry with new screenshot |
| 14 | Tab once from email to password | Lands on "Forgot password?" link | Tab TWICE |
| 15 | Protocol detection `tauri://` | Auth shim not installed, CORS blocked, splash hangs | Use `!/^https?:$/.test()` not `=== "tauri:"` |
| 16 | `handleAuthDeepLink` follows redirects | Gets 404 instead of processing callback | Add `{ redirect: "manual" }` |
| 17 | Special chars in password via xdotool | `&`, `!`, `#` interpreted as shell metacharacters | Use Gemini CU or escape properly |
| 18 | `.env` test password wrong | "Invalid email or password" | Create new account via sign-up instead |
| 19 | `xdotool type` mangles uppercase | "AI" becomes "ai" due to `--clearmodifiers` | Cosmetic — acceptable for testing |
| 20 | Gemini CU calls `wait_5_seconds` / `scroll_document` | "Unimplemented action" in script | These are implemented in the script now |
