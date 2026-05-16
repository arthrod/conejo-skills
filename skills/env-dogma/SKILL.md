---
name: env-dogma
description: Scorched-earth env/secrets refactor for Vite + Cloudflare Workers + Tauri. Use when consolidating .env sprawl, hardening secrets handling, or auditing env access patterns.
---

# Scorched Earth: Environment Variables & Secrets Refactor

You are an autonomous agent refactoring all environment variable and secret handling across a Vite + Cloudflare Workers + Tauri codebase. Your mission is to eliminate ALL dotfile-based env loading, centralize configuration into exactly two sources (wrangler.toml for worker-side, vite.config.ts `define` for client-side), and enforce a single canonical access pattern on the worker: `import { env } from 'cloudflare:workers'`.

## Architecture After This Refactor

```
┌─────────────────────────────────────────────────────────┐
│                    SOURCE OF TRUTH                       │
├──────────────────────┬──────────────────────────────────┤
│  Non-sensitive vars  │  wrangler.toml [vars]            │
│                      │  (committed to git)              │
├──────────────────────┼──────────────────────────────────┤
│  Secret names only   │  wrangler.toml [secrets]         │
│                      │  required = ["KEY_A", "KEY_B"]   │
│                      │  (committed — NO values here)    │
├──────────────────────┼──────────────────────────────────┤
│  Secret values       │  LOCAL: shell env (direnv/export)│
│                      │  CI: GitHub Actions secrets      │
│                      │  PROD: wrangler secret put       │
├──────────────────────┼──────────────────────────────────┤
│  Client-side vars    │  vite.config.ts define: {}       │
│                      │  (build-time string replacement) │
└──────────────────────┴──────────────────────────────────┘
```

## Technical Requirements

- **Wrangler config**: `wrangler.toml` (TOML, NOT jsonc)
- **Worker env access**: `import { env } from 'cloudflare:workers'`
- **Client env access**: `import.meta.env.VITE_*` via `define` in vite.config.ts
- **Tauri env access**: `import.meta.env.TAURI_ENV_*` (set by Tauri CLI on process, NOT from files)
- **Dotfile loading**: DISABLED on both Vite and Wrangler sides
- **secrets config property**: Declared in wrangler.toml — new Cloudflare feature (March 24, 2026)

## Phase 1: Audit — Find Every Violation

Run each command below. Record every hit. These are your targets.

```bash
# ── FILES THAT MUST NOT EXIST ──
find . -maxdepth 5 \
  \( -name '.env' -o -name '.env.*' -o -name '.dev.vars' -o -name '.dev.vars.*' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*'

# ── FORBIDDEN ACCESS PATTERNS (worker-side code) ──
# 1. Hono c.env usage — replaced by cloudflare:workers import
rg --type ts --type js 'c\.env\.' --glob '!node_modules' --glob '!dist'

# 2. process.env usage — forbidden in Workers
rg --type ts --type js 'process\.env\b' --glob '!node_modules' --glob '!dist' --glob '!vite.config.*' --glob '!tauri.conf.*'

# 3. Destructured env from fetch handler params
rg --type ts --type js 'fetch\s*\([^)]*\benv\b' --glob '!node_modules' --glob '!dist'
rg --type ts --type js '\(\s*(?:request|req)\s*,\s*env\b' --glob '!node_modules' --glob '!dist'

# 4. Old-style env parameter threading
rg --type ts --type js 'env:\s*Env\b' --glob '!node_modules' --glob '!dist'
rg --type ts --type js 'Bindings\b.*env' --glob '!node_modules' --glob '!dist'

# 5. Any env.ts or env.d.ts barrel files for env vars (not vite-env.d.ts)
find . -maxdepth 5 -name 'env.ts' -not -path '*/node_modules/*'

# 6. dotenv imports
rg --type ts --type js "from\s+['\"]dotenv['\"]" --glob '!node_modules'
rg --type ts --type js "require\s*\(\s*['\"]dotenv['\"]" --glob '!node_modules'

# 7. Vite loadEnv usage (we do not load from files anymore)
rg --type ts --type js 'loadEnv' --glob '!node_modules'

# ── FORBIDDEN CONFIG PATTERNS ──
# 8. Any wrangler.jsonc / wrangler.json (must be .toml)
find . -maxdepth 3 \( -name 'wrangler.json' -o -name 'wrangler.jsonc' \) -not -path '*/node_modules/*'

# 9. envDir set to anything other than false
rg 'envDir' --glob 'vite.config.*'

# 10. CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV not set in scripts
rg 'CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV' package.json
```

For each hit, record:
- File path and line number
- Current pattern used
- What it accesses (var name)
- Classification: SECRET or VARIABLE

## Phase 2: Establish the Canonical Config

### 2.1 wrangler.toml

```toml
name = "cicero-worker"
main = "src/worker.ts"
compatibility_date = "2025-09-15"
compatibility_flags = ["nodejs_compat"]

# ─── NON-SENSITIVE VARIABLES (committed, values here) ───
[vars]
ENVIRONMENT = "production"
API_HOST = "api.cicero.im"
LOG_LEVEL = "info"
# ... every non-sensitive key-value pair found in the audit

# ─── SECRETS (names only, NO values — ever) ───
[secrets]
required = [
  "OPENAI_API_KEY",
  "DATABASE_URL",
  "POSTHOG_API_KEY",
  # ... every secret name found in the audit
]

# ─── PER-ENVIRONMENT OVERRIDES ───
[env.staging]
name = "cicero-worker-staging"

[env.staging.vars]
ENVIRONMENT = "staging"
API_HOST = "staging-api.cicero.im"
LOG_LEVEL = "debug"

[env.staging.secrets]
required = [
  "OPENAI_API_KEY",
  "DATABASE_URL",
  "POSTHOG_API_KEY",
]
```

CRITICAL: `[vars]` and `[secrets]` are NON-INHERITABLE. You MUST redeclare them in every `[env.*]` block. Missing them means they vanish in that environment.

### 2.2 vite.config.ts

```typescript
import { defineConfig } from 'vite'
import { cloudflare } from '@cloudflare/vite-plugin'

const host = process.env.TAURI_DEV_HOST

export default defineConfig({
  // ── KILL .env FILE LOADING ──
  envDir: false,

  // ── TAURI_ENV_* must still reach import.meta.env ──
  // These come from the Tauri CLI process, NOT from files.
  envPrefix: ['VITE_', 'TAURI_ENV_'],

  // ── CLIENT-SIDE VARIABLES (build-time inlined) ──
  define: {
    'import.meta.env.VITE_API_URL': JSON.stringify(
      process.env.CLOUDFLARE_ENV === 'staging'
        ? 'https://staging-api.cicero.im'
        : 'https://api.cicero.im'
    ),
    'import.meta.env.VITE_POSTHOG_HOST': JSON.stringify(
      'https://us.i.posthog.com'
    ),
    // ... every VITE_* value the frontend needs
  },

  // ── TAURI CONFIGURATION ──
  clearScreen: false,
  server: {
    host: host || false,
    port: 1420,
    strictPort: true,
    hmr: host ? { protocol: 'ws', host, port: 1430 } : undefined,
  },
  build: {
    target:
      process.env.TAURI_ENV_PLATFORM === 'windows'
        ? 'chrome105'
        : 'safari13',
    minify: !process.env.TAURI_ENV_DEBUG ? 'esbuild' : false,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },

  plugins: [cloudflare()],
})
```

NOTE: `process.env.TAURI_ENV_*` and `process.env.CLOUDFLARE_ENV` in vite.config.ts are fine — this file runs in Node/Bun at build time, not in the Worker runtime. The prohibition on `process.env` applies to worker code only.

### 2.3 package.json scripts

```jsonc
{
  "scripts": {
    "dev": "CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false vite dev",
    "dev:staging": "CLOUDFLARE_ENV=staging CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false vite dev",
    "build": "CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false vite build",
    "build:staging": "CLOUDFLARE_ENV=staging CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false vite build --mode staging",
    "preview": "vite preview",
    "deploy": "wrangler deploy",
    "deploy:staging": "wrangler deploy --env staging",
    "tauri:dev": "CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false tauri dev",
    "tauri:build": "CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false tauri build",
    "typecheck:worker": "wrangler types && tsc --noEmit",
    "check:env-violations": "bash scripts/check-env-violations.sh"
  }
}
```

WINDOWS NOTE: If cross-platform is needed, use `cross-env` as a devDependency:
```jsonc
"dev": "cross-env CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false vite dev"
```

### 2.4 Type Definitions

Run `wrangler types` to generate the Env interface from `[vars]` and `[secrets] required`. Do NOT hand-write it.

For the Vite client side, maintain `src/vite-env.d.ts`:

```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_POSTHOG_HOST: string
  // Tauri injects these from the CLI process:
  readonly TAURI_ENV_PLATFORM?: string
  readonly TAURI_ENV_ARCH?: string
  readonly TAURI_ENV_DEBUG?: string
  readonly TAURI_ENV_FAMILY?: string
  readonly TAURI_ENV_PLATFORM_VERSION?: string
  readonly TAURI_ENV_PLATFORM_TYPE?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

## Phase 3: Rewrite All Worker-Side Access

### BEFORE (forbidden patterns):

```typescript
// ❌ Hono c.env
app.get('/api', (c) => {
  const key = c.env.OPENAI_API_KEY
})

// ❌ fetch handler env parameter
export default {
  async fetch(request: Request, env: Env) {
    const host = env.API_HOST
  }
}

// ❌ process.env in worker code
const key = process.env.OPENAI_API_KEY

// ❌ env.ts barrel file
export const config = { apiKey: process.env.API_KEY }

// ❌ dotenv
import 'dotenv/config'

// ❌ loadEnv
import { loadEnv } from 'vite'
```

### AFTER (the one true pattern):

```typescript
import { env } from 'cloudflare:workers'

// Access anywhere — top-level, inside functions, inside Hono handlers
const apiHost = env.API_HOST
const openaiKey = env.OPENAI_API_KEY

// Hono handlers: use the cloudflare:workers import, NOT c.env
app.get('/api', (c) => {
  const key = env.OPENAI_API_KEY  // ← from import, not c
  return c.json({ host: env.API_HOST })
})
```

For Hono typing, you can REMOVE the Bindings generic if all access goes through the `cloudflare:workers` import. If you still need `c.env` for Hono middleware that explicitly reads from context (e.g. third-party middleware), that middleware must be wrapped to inject from the import instead.

## Phase 4: Delete Forbidden Files

```bash
# Delete all dotenv files
find . -maxdepth 5 \
  \( -name '.env' -o -name '.env.*' -o -name '.dev.vars' -o -name '.dev.vars.*' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -exec rm -v {} \;

# Delete env barrel files (env.ts, not vite-env.d.ts)
# Review each one first — some may contain non-env logic
find . -maxdepth 5 -name 'env.ts' -not -path '*/node_modules/*' -exec echo "REVIEW: {}" \;

# Delete wrangler.json / wrangler.jsonc (replaced by wrangler.toml)
find . -maxdepth 3 \( -name 'wrangler.json' -o -name 'wrangler.jsonc' \) \
  -not -path '*/node_modules/*' -exec rm -v {} \;

# Remove dotenv from dependencies
# Check both dependencies and devDependencies
bun remove dotenv 2>/dev/null || true
```

## Phase 5: Update .gitignore

ADD the following to enforce no accidental re-creation:

```gitignore
# ── ENVIRONMENT FILES — FORBIDDEN ──
# All env loading is disabled. Secrets come from shell/CI/wrangler secret put.
# Do NOT create these files. See PROMPT-env-scorch.md for architecture.
.env
.env.*
.env.local
.env.*.local
.dev.vars
.dev.vars.*
```

REMOVE any entries like:
```gitignore
# These are deleted, not ignored
# .env.example  ← delete the example file too, it's misleading
```

## Phase 6: Create Violation Checker

Create `scripts/check-env-violations.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VIOLATIONS=0

echo "═══════════════════════════════════════════════"
echo "  Environment Variables Violation Checker"
echo "═══════════════════════════════════════════════"

# 1. Forbidden files
echo -e "\n${YELLOW}[1/8] Checking for forbidden dotfiles...${NC}"
DOTFILES=$(find . -maxdepth 5 \
  \( -name '.env' -o -name '.env.*' -o -name '.dev.vars' -o -name '.dev.vars.*' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null || true)
if [ -n "$DOTFILES" ]; then
  echo -e "${RED}VIOLATION: Forbidden env files found:${NC}"
  echo "$DOTFILES"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 2. process.env in worker code
echo -e "\n${YELLOW}[2/8] Checking for process.env in worker code...${NC}"
if rg --type ts --type js 'process\.env\b' \
  --glob '!node_modules' --glob '!dist' --glob '!*.config.*' \
  --glob '!scripts/*' --glob '!vite-env.d.ts' --glob '!check-env*' \
  --glob '!PROMPT*' -c 2>/dev/null; then
  echo -e "${RED}VIOLATION: process.env found in application code${NC}"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 3. c.env in Hono handlers
echo -e "\n${YELLOW}[3/8] Checking for c.env (Hono context env)...${NC}"
if rg --type ts --type js 'c\.env\.' \
  --glob '!node_modules' --glob '!dist' --glob '!PROMPT*' -c 2>/dev/null; then
  echo -e "${RED}VIOLATION: c.env found — use import { env } from 'cloudflare:workers'${NC}"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 4. dotenv imports
echo -e "\n${YELLOW}[4/8] Checking for dotenv imports...${NC}"
if rg --type ts --type js "dotenv" \
  --glob '!node_modules' --glob '!dist' --glob '!PROMPT*' --glob '!check-env*' -c 2>/dev/null; then
  echo -e "${RED}VIOLATION: dotenv import found${NC}"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 5. loadEnv from vite
echo -e "\n${YELLOW}[5/8] Checking for Vite loadEnv usage...${NC}"
if rg --type ts --type js 'loadEnv' \
  --glob '!node_modules' --glob '!dist' --glob '!PROMPT*' --glob '!check-env*' -c 2>/dev/null; then
  echo -e "${RED}VIOLATION: loadEnv found — envDir is false, do not load from files${NC}"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 6. wrangler.json(c) files
echo -e "\n${YELLOW}[6/8] Checking for wrangler.json/jsonc (must be .toml)...${NC}"
WJSON=$(find . -maxdepth 3 \( -name 'wrangler.json' -o -name 'wrangler.jsonc' \) \
  -not -path '*/node_modules/*' 2>/dev/null || true)
if [ -n "$WJSON" ]; then
  echo -e "${RED}VIOLATION: wrangler.json(c) found — use wrangler.toml:${NC}"
  echo "$WJSON"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 7. envDir not set to false
echo -e "\n${YELLOW}[7/8] Checking envDir in vite.config...${NC}"
if rg 'envDir' --glob 'vite.config.*' 2>/dev/null | grep -v 'false' | grep -q '.'; then
  echo -e "${RED}VIOLATION: envDir must be false${NC}"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

# 8. CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV in scripts
echo -e "\n${YELLOW}[8/8] Checking package.json scripts for dotenv kill switch...${NC}"
if ! rg 'CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false' package.json >/dev/null 2>&1; then
  echo -e "${RED}VIOLATION: package.json dev/build scripts must set CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false${NC}"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo -e "${GREEN}OK${NC}"
fi

echo -e "\n═══════════════════════════════════════════════"
if [ "$VIOLATIONS" -gt 0 ]; then
  echo -e "${RED}FAILED: $VIOLATIONS violation(s) found${NC}"
  exit 1
else
  echo -e "${GREEN}PASSED: No violations detected${NC}"
  exit 0
fi
```

Make it executable: `chmod +x scripts/check-env-violations.sh`

## Forbidden Patterns — Complete Reference

| Pattern | Where | Why Forbidden | Replacement |
|---|---|---|---|
| `process.env.X` | Worker code (.ts) | Not native to Workers; requires nodejs_compat; coerces to string; leaks global state | `import { env } from 'cloudflare:workers'` |
| `c.env.X` | Hono handlers | Ties access to request context; can't use at top-level or in utilities | `import { env } from 'cloudflare:workers'` |
| `env.X` via fetch param | Worker entry | Verbose; requires threading through call stack | `import { env } from 'cloudflare:workers'` |
| `import.meta.env.X` | Worker code | Vite build-time replacement — wrong runtime | `import { env } from 'cloudflare:workers'` |
| `.env` / `.env.*` files | Project root | Disabled via `envDir: false` + `CLOUDFLARE_LOAD_DEV_VARS_FROM_DOT_ENV=false` | `[vars]` in wrangler.toml / `define` in vite.config.ts |
| `.dev.vars` files | Project root | Superseded by `[secrets] required` + shell env | Shell exports / direnv / `wrangler secret put` |
| `dotenv` package | Any | No file-based env loading | Delete dependency |
| `loadEnv()` from vite | vite.config.ts | Loads from .env files we've disabled | Use `process.env` directly in config (Node context) |
| `wrangler.json(c)` | Project root | Standardized on TOML | `wrangler.toml` |
| Hand-written `Env` interface | Types | Drifts from config | `wrangler types` auto-generation |
| `env!()` in Rust with secrets | Tauri src-tauri | Embeds secret in binary at compile time — extractable | Tauri commands that read from OS keychain or runtime env |

## Allowed Patterns — Complete Reference

| Pattern | Where | Purpose |
|---|---|---|
| `import { env } from 'cloudflare:workers'` | Worker code | THE one true way to access vars and secrets |
| `import.meta.env.VITE_*` | Client React/TS | Build-time inlined via `define` in vite.config.ts |
| `import.meta.env.TAURI_ENV_*` | Client React/TS | Injected by Tauri CLI into process, passed via `envPrefix` |
| `process.env.*` in vite.config.ts | Build config only | Node/Bun context for build-time decisions |
| `process.env.*` in scripts/*.sh | Shell scripts | CI/CD and tooling |
| `std::env::var()` in Rust | Tauri backend | Runtime env for non-secret config |
| `wrangler secret put KEY` | CLI / CI | Setting secret values in Cloudflare |
| `wrangler types` | CLI | Generating typed Env interface |

## Tauri-Specific Considerations

1. **Tauri CLI injects `TAURI_ENV_*` as process-level variables.** These are NOT from files. `envDir: false` does not affect them. They reach `import.meta.env` through `envPrefix: ['VITE_', 'TAURI_ENV_']`.

2. **Tauri's `TAURI_DEV_HOST` for mobile dev** is a process env var set by `tauri dev`. Read it in vite.config.ts via `process.env.TAURI_DEV_HOST` — this is allowed because vite.config.ts runs in Node, not in the Worker.

3. **Rust-side secrets for Tauri desktop**: Do NOT use `env!()` for secrets — it embeds them in the binary. Use runtime `std::env::var()` for non-sensitive config, or the OS keychain (via `keyring` crate or Tauri's secure storage plugin) for actual secrets.

4. **Tauri conf**: `tauri.conf.json` may reference env vars like `TAURI_SIGNING_PRIVATE_KEY`. These are CI-level secrets, set in GitHub Actions, NOT in .env files.

## Process

1. Run Phase 1 audit. Record ALL findings as a checklist.
2. Classify each finding: SECRET (goes to `[secrets] required`) or VARIABLE (goes to `[vars]` or `define`).
3. Create wrangler.toml per Phase 2.1 with all discovered vars and secrets.
4. Update vite.config.ts per Phase 2.2 with all client-side defines.
5. Update package.json scripts per Phase 2.3.
6. Rewrite every worker-side file per Phase 3.
7. Delete forbidden files per Phase 4.
8. Update .gitignore per Phase 5.
9. Create and run violation checker per Phase 6.
10. Run `wrangler types` to regenerate the Env interface.
11. Run `bun run typecheck:worker` — fix any type errors.
12. Run `bun run check:env-violations` — must pass clean.
13. Run existing test suite — all tests must pass.
14. Commit with message: `refactor: scorch-earth env vars — centralize to wrangler.toml + vite define`

## IMPORTANT: What NOT to Touch

- `process.env` inside `vite.config.ts` — this runs in Node/Bun, it's fine
- `process.env` inside `scripts/` shell helpers and Node scripts — fine
- `process.env` inside `tauri.conf.json` template variables — fine
- `TAURI_ENV_*` access via `import.meta.env` — these come from the CLI process
- Rust `std::env::var()` for non-secret runtime config — fine
- Third-party packages that internally use process.env (e.g. PostHog SDK) — out of scope
