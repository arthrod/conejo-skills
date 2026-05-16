---
name: better-auth-tauri-pitfalls
description: Debugging guide and platform-specific gotchas for @daveyplate/better-auth-tauri. Use when troubleshooting auth failures in Tauri desktop apps, diagnosing 404 callback errors, fixing macOS cookie/deep-link issues, or debugging the OAuth redirect flow.
---

# Better Auth Tauri Plugin - Pitfalls & Debugging

This skill covers every known failure mode, platform-specific gotcha, and debugging technique for `@daveyplate/better-auth-tauri`.

---

## Pitfall #1: 404 Error After Successful OAuth (The Silent Killer)

### Symptoms
- OAuth completes in browser, success page appears, deep link fires
- Tauri receives the deep link but `onError` fires with `{ status: 404, statusText: "Not Found" }`
- Cookies ARE actually set - if you force-reload the app, user is authenticated
- Browser logs show: `handleAuthDeepLink error {status: 404, statusText: "Not Found"}`

### Root Cause
After `handleAuthDeepLink()` calls `authClient.$fetch()` to process the OAuth callback, the server:
1. Validates the OAuth code and creates a session (sets cookie)
2. Returns a **302 redirect** to the `callbackURL` (default: `"/"`)
3. Tauri HTTP client **follows** the redirect to `GET /`
4. If your server has no handler for `GET /`, it returns 404
5. The plugin sees 404 and calls `onError` even though auth actually succeeded

### Fix
Add a root route handler on your server:

```typescript
// Elysia
app.get("/", () => ({ status: "OK" }))

// Express
app.get("/", (req, res) => res.json({ status: "OK" }))

// Hono
app.get("/", (c) => c.json({ status: "OK" }))
```

**Or** set `callbackURL` in the server plugin to a path that already exists on your server.

### Why This Is Subtle
The 302 status code is actually **expected and handled** by the plugin - `handleAuthDeepLink` treats `error.status === 302` as success. But the 404 from the followed redirect is a different error that gets passed to `onError`.

---

## Pitfall #2: macOS Deep Links Don't Work in Development

### Symptoms
- Social auth works fine on Windows/Linux dev mode
- On macOS, the browser shows the success page but the app never receives the deep link
- `onOpenUrl` listener never fires

### Root Cause
macOS dev mode runs in a local web container (localhost) that does NOT support native URL scheme handling. Deep links require the app to be registered with the OS as a handler for the scheme, which only happens with a proper `.app` bundle.

### Fix
1. Build production binary: `tauri build`
2. Drag the `.app` from `src-tauri/target/release/bundle/macos/` to `/Applications/`
3. Run from Applications folder
4. Deep links will now work

### Important
This is a macOS-only limitation. Windows and Linux dev mode support deep links natively.

---

## Pitfall #3: macOS Cookies Don't Persist in Production

### Symptoms
- Auth completes successfully (no errors), `onSuccess` fires
- But `useSession()` / `getSession()` returns null
- Refreshing the page doesn't help
- Works fine in dev mode, breaks in production build

### Root Cause
macOS production Tauri apps run under the `tauri:` protocol (not `http:`/`https:`). The standard browser `fetch()` does not properly handle cookies under this protocol.

### Fix (MANDATORY for macOS)
Use `@tauri-apps/plugin-http` fetch for macOS production:

```typescript
import { isTauri } from "@tauri-apps/api/core"
import { fetch as tauriFetch } from "@tauri-apps/plugin-http"
import { platform } from "@tauri-apps/plugin-os"
import { createAuthClient } from "better-auth/react"

export const authClient = createAuthClient({
  fetchOptions: {
    customFetchImpl: (...params) =>
      isTauri() && platform() === "macos" && window.location.protocol === "tauri:"
        ? tauriFetch(...params)
        : fetch(...params)
  }
})
```

### Why Three Conditions?
- `isTauri()`: Only use Tauri fetch inside Tauri (not in web browser)
- `platform() === "macos"`: Only macOS has this cookie bug
- `window.location.protocol === "tauri:"`: Only in production builds (dev uses `http:`)

---

## Pitfall #4: Scheme Mismatch (Triple Consistency Required)

### Symptoms
- Deep links don't trigger the app
- Or deep links trigger the app but `handleAuthDeepLink` ignores them
- Or server doesn't append callback URLs to social providers

### Root Cause
The scheme must match **exactly** in three places:

1. **`tauri.conf.json`**: `plugins.deep-link.desktop.schemes: ["my-app"]`
2. **Server plugin**: `tauri({ scheme: "my-app" })`
3. **Client setup**: `setupBetterAuthTauri({ scheme: "my-app" })`

A mismatch in ANY of these causes silent failures. The scheme is used WITHOUT `://` in all three configurations.

---

## Pitfall #5: Using authClient.signIn.social() Directly

### Symptoms
- Social auth opens in the Tauri webview (not default browser)
- Or OAuth flow completes but no deep link fires
- Or server doesn't detect it's a Tauri request (no Platform header)

### Root Cause
Calling `authClient.signIn.social()` directly bypasses the Tauri-specific handling:
- No `Platform` header sent (server doesn't append callback URL)
- No `disableRedirect: true` (causes in-app redirect instead of browser open)
- No Opener plugin integration (doesn't open in default browser)

### Fix
Always use the provided helper:

```typescript
import { signInSocial } from "@daveyplate/better-auth-tauri"

signInSocial({ authClient, provider: "google" })
```

---

## Pitfall #6: basePath Normalization

### Symptoms
- Auth works in development but fails in production
- Or auth works when basePath is `/api/auth` but breaks with custom basePath

### Root Cause
The plugin internally normalizes ALL paths to `/api/auth`:

```typescript
// From tauri.ts
const basePath = ctx.context.options.basePath ?? "/api/auth"
url.pathname = url.pathname.replace(basePath, "/api/auth")
```

And `handleAuthDeepLink` hardcodes:
```typescript
const basePath = "/api/auth/"
```

If your server uses a custom `basePath` (e.g., `/auth`), the deep link URLs may not match what the client expects.

### Current Behavior
The plugin replaces your custom basePath with `/api/auth` in the deep link URLs. This means:
- Deep links always use `/api/auth/callback/...` format
- The client always looks for `/api/auth/` prefix in deep link URLs
- Your actual server basePath is handled transparently

### Potential Issue
If you have routing that specifically depends on a non-standard basePath appearing in URLs, the normalization may cause issues. The plugin was designed around `/api/auth` as the canonical path.

---

## Pitfall #7: Opener Plugin Detection Logic

### Symptoms
- Social auth doesn't open in default browser on some platforms
- Or social auth opens in browser on macOS dev mode (but deep links won't work there anyway)

### Root Cause
The Opener plugin is considered "enabled" only when:

```typescript
const isOpenerEnabled = () =>
  isTauri() &&
  (window.location.protocol === "tauri:" || platform() !== "macos")
```

This means:
- **macOS production** (`tauri:` protocol): Opener enabled, opens in browser
- **macOS dev** (`http:` protocol): Opener **disabled**, falls back to in-app redirect
- **Windows/Linux** (any protocol): Opener enabled, opens in browser

macOS dev mode intentionally falls back because deep links don't work there anyway.

---

## Pitfall #8: getCurrent() Called Multiple Times

### Symptoms
- Auth callback processed twice on app launch
- Duplicate session creation or double navigation

### Root Cause
`setupBetterAuthTauri` uses `sessionStorage` to prevent `getCurrent()` (which reads any pending deep link URL) from being called multiple times:

```typescript
if (!sessionStorage.getItem("getCurrentUrlChecked")) {
  if (getCurrentWebviewWindow().label === mainWindowLabel) {
    getCurrent().then(handleUrls)
    sessionStorage.setItem("getCurrentUrlChecked", "true")
  }
}
```

This only runs once per session. But `onOpenUrl` continues to listen for subsequent deep links.

### Potential Issue
If you have multiple windows and the wrong `mainWindowLabel` is configured, `getCurrent()` won't fire and the initial deep link from app launch may be lost.

---

## Pitfall #9: Mobile Platform Detection Silently Changes Behavior

### Symptoms
- Auth flow works differently on mobile Tauri builds
- Social providers lose their custom redirectURI on mobile

### Root Cause
The `appendCallbackURL` function checks the `Platform` header:

```typescript
if (platform && !["android", "ios"].includes(platform)) {
  // Desktop: append scheme callback URL
} else {
  // Mobile: REMOVE custom redirectURI entirely
  ctx.context.options.socialProviders![key]!.redirectURI = undefined
}
```

On mobile (iOS/Android), the plugin **removes** any custom `redirectURI` from social providers, falling back to the provider's default. This is intentional - mobile has its own deep link handling - but can be surprising if you set a custom `redirectURI` expecting it to apply everywhere.

---

## Pitfall #10: Bearer Tokens Are NOT Needed

### Common Misconception
"Desktop apps can't use cookies for auth, I need Bearer tokens or JWT."

### Reality
The Tauri HTTP Plugin (`@tauri-apps/plugin-http`) handles cookies without CORS restrictions. Since Tauri makes requests from a native context (not a browser sandbox), there are no cross-origin issues.

- Cookies work normally via Tauri HTTP plugin
- No Bearer token management overhead
- No token refresh logic needed
- Session management handled entirely by Better Auth's cookie-based system

Do NOT add the `bearer` or `jwt` Better Auth plugins unless you have a specific non-Tauri reason.

---

## Debugging Checklist

### Enable Debug Logs (Both Sides)

**Server:**
```typescript
tauri({ scheme: "my-app", debugLogs: true })
```

**Client:**
```typescript
setupBetterAuthTauri({ ..., debugLogs: true })
```

### Server Logs to Watch For

```
[Better Auth Tauri] Request URL: ...          → Every request through middleware
[Better Auth Tauri] Appending callback URL... → Social provider redirect modified
[Better Auth Tauri] Callback URL: ...         → Deep link callback detected
[Better Auth Tauri] Redirecting to: ...       → Success page redirect
```

### Client Logs to Watch For

```
[Better Auth Tauri] check getCurrent() url           → Initial deep link check
[Better Auth Tauri] handleAuthDeepLink fetch ...      → Processing deep link
[Better Auth Tauri] handleAuthDeepLink response ...   → Server response
[Better Auth Tauri] handleAuthDeepLink onSuccess ...  → Auth completed
[Better Auth Tauri] handleAuthDeepLink error ...      → Auth failed
```

### Diagnostic Steps for Auth Failures

1. **Enable `debugLogs: true`** on both server and client
2. **Check server logs** - Is the Platform header received? Is callback URL being appended?
3. **Check browser** - Does the success page appear? Does it attempt the deep link redirect?
4. **Check client logs** - Does `onOpenUrl` fire? What URL does `handleAuthDeepLink` receive?
5. **Check the scheme** - Triple-match between tauri.conf.json, server plugin, and client setup
6. **Check root route** - Does `GET /` return 200 on your server?
7. **macOS?** - Are you running a production build from Applications folder?
8. **macOS cookies?** - Is `customFetchImpl` configured with `tauriFetch`?

### Network Debugging

The deep link callback URL looks like:
```
my-app://api/auth/callback/google?callbackURL=%2F&code=ABC123&state=XYZ789
```

The client extracts and fetches:
```
/callback/google?callbackURL=%2F&code=ABC123&state=XYZ789
```

If the server returns 302 to `/`, the Tauri HTTP client follows the redirect. If `/` returns 404, you get the most common failure mode (Pitfall #1).

---

## Platform Compatibility Matrix

| Feature | macOS Dev | macOS Prod | Windows Dev | Windows Prod | Linux Dev | Linux Prod |
|---------|-----------|------------|-------------|--------------|-----------|------------|
| Deep Links | No | Yes (from /Applications) | Yes | Yes | Yes | Yes |
| Cookies (standard fetch) | Yes | **No** | Yes | Yes | Yes | Yes |
| Cookies (tauriFetch) | N/A | Yes | Yes | Yes | Yes | Yes |
| Opener (default browser) | No (fallback) | Yes | Yes | Yes | Yes | Yes |
| Social OAuth | In-app only | Default browser | Default browser | Default browser | Default browser | Default browser |

---

## Related Skills

- **[sawy-better-auth-ui-tauri-repro](/Users/arthrod/.claude/skills/sawy-better-auth-ui-tauri-repro/SKILL.md)**: Reproduction and fix for the `@daveyplate/better-auth-ui` module-load-time crash in non-HTTP environments (`BetterAuthError: Invalid base URL: tauri://localhost`). Covers pnpm patching, upstream fix proposals, and diagnostic tooling.
- **[better-auth-tauri-setup](/Users/arthrod/.claude/skills/better-auth-tauri-setup/SKILL.md)**: Step-by-step integration guide for `@daveyplate/better-auth-tauri` — server plugin, client setup, social OAuth, deep links.

<!-- cross-ref:start -->

## See also (related skills — Better Auth family)

If your issue relates to:
- **Better Auth integration overview** — check `better-auth` if appropriate.
- **best-practices guide** — check `better-auth-best-practices` if appropriate.
- **create the auth layer (initial scaffolding)** — check `better-auth-create-auth` if appropriate.
- **email/password, password reset, verification policies** — check `better-auth-email-password` if appropriate.
- **explain a specific error code + provide fix** — check `better-auth-explain-error` if appropriate.
- **organization/team plugin** — check `better-auth-organization` if appropriate.
- **OAuth/email/magic-link/social provider config** — check `better-auth-providers` if appropriate.
- **rate limit, CSRF, trusted origins, secrets, OAuth security** — check `better-auth-security` if appropriate.
- **twoFactor plugin enforcement** — check `better-auth-two-factor` if appropriate.
- **wiring Better Auth into a Tauri desktop app** — check `better-auth-tauri-setup` if appropriate.
- **reproduction guide for the better-auth-ui crash on Tauri v2** — check `sawy-better-auth-ui-tauri-repro` if appropriate.

<!-- cross-ref:end -->


---

# better-auth-ui crash on Tauri v2 (reproduction & fix)

_Merged from former `sawy-better-auth-ui-tauri-repro` skill — the specific BetterAuthError crash with `window.location.origin === 'tauri://localhost'` plus the patch._


# Better Auth UI + Tauri Reproduction Skill

Guide for reproducing, diagnosing, patching, and upstreaming the `@daveyplate/better-auth-ui`
crash in Tauri v2 desktop applications.

## Repository

- **Origin**: `https://github.com/sawy/better-auth-ui-tauri-repro`
- **Stack**: React 19 + Vite 6 + TypeScript 5 + Tauri 2.x + pnpm
- **Key deps**: `@daveyplate/better-auth-ui@^3.3.11`, `better-auth@^1.4.10`

## Bug Summary

Two bugs exist in `@daveyplate/better-auth-ui`:

### Bug 1 (Critical): Module-load-time crash in non-HTTP environments

`src/types/auth-client.ts` calls `createAuthClient()` without `baseURL` at **module load time**.
`better-auth` falls back to `window.location.origin`, which is `tauri://localhost` in Tauri
production builds. `better-auth` throws because `tauri://` is not `http://` or `https://`.

The crash happens **before any React component renders**, so even a properly configured
`AuthUIProvider` with a correct `baseURL` cannot prevent it.

```
BetterAuthError: Invalid base URL: tauri://localhost. URL must include 'http://' or 'https://'
```

### Bug 2 (Secondary): Direct import of type-inference authClient

`src/components/settings/teams/user-team-cell.tsx` imports the module-level `authClient` directly
and uses it for an actual API call (`authClient.organization.setActiveTeam()`). It should use
`authClient` from `AuthUIContext` instead.

## Key Insight: Dev vs Production Divergence

The bug does NOT appear in development mode because Vite dev server serves from
`http://localhost:1420` (valid HTTP). It only manifests in **production builds** where
`window.location.origin` becomes `tauri://localhost`.

## Project Structure

```
better-auth-ui-tauri-repro/
  index.html                      # Vite entry point
  package.json                    # pnpm project, patched dependencies
  vite.config.ts                  # Vite + React, port 1420
  tsconfig.json                   # ES2020, bundler resolution
  src/
    main.tsx                      # React 19 root
    App.tsx                       # Minimal repro: imports AuthUIProvider
  src-tauri/
    tauri.conf.json               # Tauri config: devUrl, frontendDist
    Cargo.toml                    # Rust deps: tauri 2.9.5
    src/lib.rs                    # Tauri builder with log plugin
    src/main.rs                   # Entry point
    capabilities/default.json     # core:default permissions
  patches/
    @daveyplate__better-auth-ui.patch  # pnpm patch adding baseURL placeholder
```

## Reproduction Workflow

1. Clone the repo
2. Run `pnpm install`
3. Build Tauri production: `pnpm tauri build --debug`
4. Open the built app from `src-tauri/target/debug/bundle/`
5. Observe the crash

To verify the fix, apply the patch (already configured in `package.json` under
`pnpm.patchedDependencies`), reinstall, rebuild, and confirm the app loads.

## The Patch Fix

The pnpm patch in `patches/@daveyplate__better-auth-ui.patch` adds `baseURL: "http://localhost:1212"`
to both `dist/index.cjs` and `dist/index.js` in the `createAuthClient()` call. This prevents the
crash because the module-level client is only used for **type inference**, never for actual API calls.

### Patch format (pnpm patchedDependencies)

In `package.json`:
```json
{
  "pnpm": {
    "patchedDependencies": {
      "@daveyplate/better-auth-ui": "patches/@daveyplate__better-auth-ui.patch"
    }
  }
}
```

## Proposed Upstream Fixes

### Fix 1: Placeholder baseURL in `src/types/auth-client.ts`

```typescript
export const authClient = createAuthClient({
  baseURL: "http://localhost",
  plugins: [/* ... */]
})
```

### Fix 2: Use context authClient in `UserTeamCell`

```diff
- import { authClient } from "../../../types/auth-client"

  export function UserTeamCell({ ... }) {
    const {
+     authClient,
      hooks: { useSession },
    } = useContext(AuthUIContext)
  }
```

## Tauri-Specific Configuration

### tauri.conf.json critical fields

```json
{
  "build": {
    "frontendDist": "../dist",
    "devUrl": "http://localhost:1420",
    "beforeDevCommand": "pnpm dev",
    "beforeBuildCommand": "pnpm build"
  },
  "app": {
    "security": { "csp": null }
  }
}
```

### Vite config for Tauri

```typescript
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: { port: 1420, strictPort: true },
})
```

### Rust side (minimal)

`lib.rs` uses `tauri::Builder::default()` with optional `tauri_plugin_log` in debug mode.
`main.rs` has `#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]` to suppress
console on Windows release builds.

## Affected Environments

Any environment where `window.location.origin` is not `http://` or `https://`:

| Environment     | `window.location.origin` | Affected? |
|----------------|--------------------------|-----------|
| Vite dev       | `http://localhost:1420`  | No        |
| Tauri prod     | `tauri://localhost`      | Yes       |
| Electron       | `file://`                | Yes       |
| Capacitor      | `capacitor://localhost`  | Yes       |
| React Native   | N/A (no window)          | Yes       |

## Diagnostic Checklist

When debugging this class of error:

1. Check `window.location.origin` in the target environment
2. Search for `createAuthClient` calls without explicit `baseURL` in dependency source
3. Determine if the call happens at module load time vs. runtime
4. Check if the library re-exports or wraps `better-auth` client creation
5. Verify the error occurs only in production builds (not dev server)
6. Apply pnpm patch or fork to add placeholder `baseURL`

## References

- **[architecture.md](references/architecture.md)**: Detailed file-by-file breakdown of every source file, dependency versions, Tauri Rust configuration, and build pipeline
- **[debugging-guide.md](references/debugging-guide.md)**: Step-by-step debugging procedures, common error patterns, environment-specific gotchas, and advanced diagnostic techniques

<!-- cross-ref:start -->

## See also (related skills — Better Auth family)

If your issue relates to:
- **Better Auth integration overview** — check `better-auth` if appropriate.
- **best-practices guide** — check `better-auth-best-practices` if appropriate.
- **create the auth layer (initial scaffolding)** — check `better-auth-create-auth` if appropriate.
- **email/password, password reset, verification policies** — check `better-auth-email-password` if appropriate.
- **explain a specific error code + provide fix** — check `better-auth-explain-error` if appropriate.
- **organization/team plugin** — check `better-auth-organization` if appropriate.
- **OAuth/email/magic-link/social provider config** — check `better-auth-providers` if appropriate.
- **rate limit, CSRF, trusted origins, secrets, OAuth security** — check `better-auth-security` if appropriate.
- **twoFactor plugin enforcement** — check `better-auth-two-factor` if appropriate.
- **wiring Better Auth into a Tauri desktop app** — check `better-auth-tauri-setup` if appropriate.
- **Tauri-specific gotchas (cookies, deep links, macOS, 404 callbacks)** — check `better-auth-tauri-pitfalls` if appropriate.

<!-- cross-ref:end -->

