---
name: better-auth-tauri-setup
description: Integration guide for @daveyplate/better-auth-tauri - cookie-based auth in Tauri v2 desktop apps via deep links. Use when setting up Better Auth in a Tauri application, configuring social OAuth for desktop, or wiring up deep link authentication flows.
---

# Better Auth Tauri Plugin - Setup Guide

**Package**: `@daveyplate/better-auth-tauri` (v0.1.6+)
**Purpose**: Enables cookie-based authentication in Tauri v2 desktop apps using deep links for OAuth callback flows.

---

## Architecture Overview

The plugin works in two halves: a **server plugin** (Better Auth middleware) and a **client setup** (Tauri deep link listener). Social OAuth opens in the user's default browser, completes there, then deep-links back into the Tauri app to finalize the session.

### Complete Social Auth Flow

```
1. User clicks "Sign in with Google" in Tauri app
2. signInSocial() sends request to /api/auth/sign-in/social with Platform header
3. Server middleware appends scheme callback to OAuth redirectURI:
   → /api/auth/callback/google?callbackURL=my-app://
4. Server returns Google OAuth URL; client opens it in default browser
5. User authenticates in browser; Google redirects to callback URL
6. Server middleware intercepts callbackURL with scheme prefix
7. Server redirects to /api/auth/callback/success?redirectTo=my-app://api/auth/callback/google?...
8. Success page HTML triggers: window.location.href = 'my-app://...'
9. OS deep link activates Tauri app
10. Client handleAuthDeepLink() calls authClient.$fetch() to process callback
11. Server validates OAuth code, creates session, sets cookie
12. onSuccess callback fires - auth complete
```

---

## Prerequisites

### Required Tauri Plugins (peer dependencies)

```bash
bun add @tauri-apps/api @tauri-apps/plugin-deep-link @tauri-apps/plugin-http @tauri-apps/plugin-os @tauri-apps/plugin-opener better-auth
```

| Plugin | Min Version | Purpose |
|--------|-------------|---------|
| `@tauri-apps/api` | >=2.5.0 | Core Tauri API, `isTauri()` check |
| `@tauri-apps/plugin-deep-link` | >=2.2.1 | URL scheme handling (`onOpenUrl`) |
| `@tauri-apps/plugin-http` | >=2.4.3 | HTTP with cookie support (macOS fix) |
| `@tauri-apps/plugin-os` | >=2.2.1 | Platform detection |
| `@tauri-apps/plugin-opener` | >=2.2.6 | Open OAuth URLs in default browser |
| `better-auth` | >=1.2.7 | Authentication framework |

### Tauri Deep Link Config

In `tauri.conf.json`:

```json
{
  "plugins": {
    "deep-link": {
      "desktop": {
        "schemes": ["my-app"]
      }
    }
  }
}
```

---

## Server Setup

### Plugin Registration (auth.ts)

```typescript
import { betterAuth } from "better-auth"
import { tauri } from "@daveyplate/better-auth-tauri/plugin"

export const auth = betterAuth({
  // ... your existing config
  plugins: [
    tauri({
      scheme: "my-app",        // Must match tauri.conf.json and client
      callbackURL: "/",        // Where to redirect after auth (default: "/")
      successText: "Authentication successful! You can close this window.",
      successURL: undefined,   // Custom success page URL (gets ?redirectTo param)
      debugLogs: false,        // Enable server-side debug logging
    }),
  ],
})
```

### Plugin Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `scheme` | `string` | **required** | Deep link scheme (without `://`) |
| `callbackURL` | `string` | `"/"` | Post-auth redirect path |
| `successText` | `string` | Generic message | Text shown on browser success page |
| `successURL` | `string` | `undefined` | Custom success page URL (receives `?redirectTo=`) |
| `debugLogs` | `boolean` | `false` | Log middleware activity to console |

### What the Server Plugin Does

The plugin registers:

1. **Before-hook middleware** on all routes (except `/reset-password` and `/callback/success`):
   - `appendCallbackURL()`: On `/sign-in/social` requests with a `Platform` header (non-mobile), modifies each social provider's `redirectURI` to include `?callbackURL=scheme://`
   - `checkCallbackURL()`: On any request where `callbackURL` query param starts with `scheme://`, strips the scheme and redirects to the success page with the deep link URL encoded in `?redirectTo=`

2. **Endpoint** `/callback/success`: Returns HTML success page with embedded `<script>window.location.href = '{deepLinkURL}'</script>` to trigger the OS deep link

---

## Client Setup

### Auth Client with macOS Cookie Fix

**Critical**: macOS production builds require `@tauri-apps/plugin-http` for cookies to work.

```typescript
// lib/auth-client.ts
import { isTauri } from "@tauri-apps/api/core"
import { fetch as tauriFetch } from "@tauri-apps/plugin-http"
import { platform } from "@tauri-apps/plugin-os"
import { createAuthClient } from "better-auth/react" // or "better-auth/client"

export const authClient = createAuthClient({
  fetchOptions: {
    customFetchImpl: (...params) =>
      isTauri() && platform() === "macos" && window.location.protocol === "tauri:"
        ? tauriFetch(...params)
        : fetch(...params)
  }
})
```

### Standard JS/TS Setup

```typescript
import { setupBetterAuthTauri } from "@daveyplate/better-auth-tauri"
import { authClient } from "./lib/auth-client"

const cleanup = setupBetterAuthTauri({
  authClient,
  scheme: "my-app",           // Must match server config
  debugLogs: false,
  mainWindowLabel: "main",    // Tauri window label (default: "main")
  onRequest: (href) => {
    console.log("Processing auth callback:", href)
  },
  onSuccess: (callbackURL) => {
    window.location.href = callbackURL || "/"
  },
  onError: (error) => {
    // error: { status: number, statusText: string, code?: string, message?: string }
    console.error("Auth failed:", error.status, error.statusText)
  },
})

// Call cleanup() when done (e.g., component unmount)
```

### React Setup

```tsx
import { useBetterAuthTauri } from "@daveyplate/better-auth-tauri/react"
import { authClient } from "./lib/auth-client"

function App() {
  useBetterAuthTauri({
    authClient,
    scheme: "my-app",
    onSuccess: (callbackURL) => {
      navigate(callbackURL || "/")
    },
    onError: (error) => {
      toast.error(`Auth failed: ${error.statusText}`)
    },
  })

  return <YourApp />
}
```

### Svelte Setup

```svelte
<script>
  import { onMount, onDestroy } from "svelte"
  import { setupBetterAuthTauri } from "@daveyplate/better-auth-tauri"
  import { authClient } from "./lib/auth-client"
  import { goto } from "$app/navigation"

  let cleanup
  onMount(() => {
    cleanup = setupBetterAuthTauri({
      authClient,
      scheme: "my-app",
      onSuccess: (callbackURL) => goto(callbackURL || "/"),
      onError: (error) => console.error("Auth error:", error),
    })
  })
  onDestroy(() => cleanup?.())
</script>
```

---

## Social Sign-In

Social auth opens in the user's default browser (reuses logged-in sessions). Use the provided helper:

```tsx
import { signInSocial } from "@daveyplate/better-auth-tauri"
import { authClient } from "./lib/auth-client"

<button onClick={async () => {
  const { data, error } = await signInSocial({
    authClient,
    provider: "google",  // Any configured social provider
  })
  if (error) console.error("Social sign-in error:", error)
}}>
  Sign in with Google
</button>
```

### What signInSocial Does

1. Checks if Opener plugin is available (`isTauri()` + correct protocol)
2. Sends sign-in request with `Platform` header (triggers server-side callback URL appending)
3. Sets `disableRedirect: true` to prevent in-app redirect
4. Opens returned OAuth URL in default browser via `openUrl()`
5. Supports `fetchOptions.throw: true` for exception-based error handling

### Non-Social Auth (Magic Link, Email OTP)

Works via the `callbackURL` plugin option. The email link contains the deep link scheme directly. No special client-side helper needed - just configure `scheme` in the server plugin and the link in the email will deep-link back to the app.

---

## Package Exports

```
@daveyplate/better-auth-tauri          → setupBetterAuthTauri, signInSocial, handleAuthDeepLink
@daveyplate/better-auth-tauri/react    → useBetterAuthTauri (React hook)
@daveyplate/better-auth-tauri/plugin   → tauri (server plugin factory)
```

---

## Quick Checklist

- [ ] Install all 5 Tauri plugin peer dependencies
- [ ] Register deep link scheme in `tauri.conf.json`
- [ ] Add `tauri()` plugin to server `betterAuth()` config with matching scheme
- [ ] Configure `customFetchImpl` in auth client for macOS cookies
- [ ] Call `setupBetterAuthTauri()` (or `useBetterAuthTauri`) in app entry point
- [ ] Use `signInSocial()` helper for social providers (not `authClient.signIn.social()` directly)
- [ ] Ensure server has a root route handler (`GET /`) to avoid 404 on post-auth redirect
- [ ] Scheme must be identical across: `tauri.conf.json`, server plugin, and client setup

---

## Related Skills

- **[sawy-better-auth-ui-tauri-repro](/Users/arthrod/.claude/skills/sawy-better-auth-ui-tauri-repro/SKILL.md)**: Reproduction and fix for the `@daveyplate/better-auth-ui` module-load-time crash in non-HTTP environments (`BetterAuthError: Invalid base URL: tauri://localhost`). Covers pnpm patching, upstream fix proposals, and diagnostic tooling.
- **[better-auth-tauri-pitfalls](/Users/arthrod/.claude/skills/better-auth-tauri-pitfalls/SKILL.md)**: Debugging guide covering 10 known pitfalls — 404 after OAuth, macOS deep links, cookie persistence, scheme mismatches, and more.

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
- **Tauri-specific gotchas (cookies, deep links, macOS, 404 callbacks)** — check `better-auth-tauri-pitfalls` if appropriate.
- **reproduction guide for the better-auth-ui crash on Tauri v2** — check `sawy-better-auth-ui-tauri-repro` if appropriate.

<!-- cross-ref:end -->

