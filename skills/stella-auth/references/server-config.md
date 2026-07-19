# Server configuration

Steps 1–5 of the build order. Reference: `apps/api/src/lib/auth.ts`.

## 1. Env schema

Validate at boot with Valibot. Cross-field rules matter as much as the
individual ones.

```ts
BETTER_AUTH_SECRET: v.pipe(v.string(), v.minLength(32)),
BETTER_AUTH_URL: v.pipe(v.string(), v.url()),
BETTER_AUTH_COOKIE_PREFIX: v.optional(v.pipe(v.string(), v.regex(/^[\w-]+$/))),
FRONTEND_URL: v.pipe(v.string(), v.url()),
EXTENSION_ORIGIN: v.optional(v.pipe(v.string(), v.url())),
GOOGLE_AUTH_CLIENT_ID / GOOGLE_AUTH_CLIENT_SECRET,
MICROSOFT_AUTH_CLIENT_ID / _SECRET / _TENANT_ID,
SELFHOST_LOCAL_PASSWORD_AUTH,
SELFHOST_BOOTSTRAP_TOKEN: v.optional(v.pipe(v.string(), v.minLength(32))),
E2E_DISABLE_AUTH_RATE_LIMIT,          // guarded to NODE_ENV=development
EMAIL_PROVIDER: v.picklist(["ses", "smtp"]),
```

Cross-field checks worth writing:

- Microsoft tenant ID is **required** if either Microsoft client field is set.
  A tenant-less Microsoft app accepts logins from every Azure tenant on earth.
- Any test/e2e escape hatch (`E2E_DISABLE_AUTH_RATE_LIMIT`) must assert
  `NODE_ENV === "development"` in the schema itself, so it cannot be flipped on
  in production by an env var alone.

Frontend gets its own schema: `VITE_API_URL`, plus a `VITE_SELFHOST` flag that
gates which sign-in options render.

## 2. Schema + RLS

Better Auth tables (`user`, `session`, `account`, `verification`,
`organization`, `member`, `invitation`, `jwks`, and the `oauth*` set if acting
as an authorization server), each with RLS policies attached in the same file.

Customizations that earn their place:

**Explicit column grants for the scoped role.** The Drizzle adapter fetches full
user rows during session resolution, so the low-privilege application role needs
every user column. Declare it exhaustively so adding a column is a compile
error, not a runtime 500:

```ts
export const AUTH_USER_STELLA_SELECT_COLUMNS = {
  id: "id", email: "email", /* ... */
} satisfies Record<keyof InferSelectModel<typeof user>, string>;
```

Back it with a migration test asserting the grants exist.

**Credential singleton as a partial unique index.** For self-host instances
where exactly one password account may exist, enforce it in the database, not in
a handler:

```ts
uniqueIndex("account_credential_singleton_uidx")
  .on(table.providerId)
  .where(sql`${table.providerId} = 'credential'`)
```

**Session carries the active tenant.** `session.activeOrganizationId` plus a
composite index on `(userId, activeOrganizationId)` — this is read on every
authenticated request.

**Soft delete on `user`** (`deletedAt`), because hard-deleting a user in a system
with audit trails orphans the trail.

## 3. The lazy singleton

```ts
const createAuth = () => betterAuth({ /* ... */ });

let cached: ReturnType<typeof createAuth> | undefined;
export const getAuth = () => (cached ??= createAuth());
```

`betterAuth()` eagerly resolves the Drizzle adapter, which reaches into the DB
module. Calling it at module scope means module evaluation order decides whether
you get a TDZ error — non-deterministic, and it usually shows up first under the
test runner.

## Core options

```ts
betterAuth({
  trustedOrigins: [
    ...frontendOrigins({ frontendUrl: env.FRONTEND_URL, isDev: env.isDev }),
    ...(env.isDev ? ["chrome-extension://*"] : []),
    ...(env.EXTENSION_ORIGIN ? [env.EXTENSION_ORIGIN] : []),
  ],
  disabledPaths: ["/token"],
  session: {
    expiresIn: 60 * 60 * 24 * 7,   // 7 days
    updateAge: 60 * 60 * 24,       // refresh once per day
    storeSessionInDatabase: true,
  },
  advanced: {
    ...(cookiePrefix ? { cookiePrefix } : {}),   // dev only
    useSecureCookies: !env.isDev,
  },
  database: drizzleAdapter(rootDb, { provider: "pg", schema: authSchema, transaction: true }),
})
```

Note `disabledPaths: ["/token"]` — turn off endpoints you do not consume. The
JWT plugin is present only for its `/jwks` endpoint.

Note the **root** DB handle here: Better Auth needs unscoped access to resolve
sessions before any tenant context exists. Every *other* query in the app goes
through a scoped handle.

## Sign-in methods

**Passwordless first.** Email OTP is the primary method; it removes password
storage, reset flows, and credential-stuffing surface in one move.

**Social providers are conditional on their env creds** — spread in only when
complete, so a partially-configured instance boots with the provider absent
rather than broken:

```ts
socialProviders: {
  ...(env.GOOGLE_AUTH_CLIENT_ID && env.GOOGLE_AUTH_CLIENT_SECRET
    ? { google: { clientId: ..., clientSecret: ... } } : {}),
  ...(env.MICROSOFT_AUTH_CLIENT_ID && env.MICROSOFT_AUTH_CLIENT_SECRET && env.MICROSOFT_AUTH_TENANT_ID
    ? { microsoft: { clientId: ..., clientSecret: ..., tenantId: ... } } : {}),
}
```

Expose the resolved set to the frontend via a `GET /auth/capabilities` endpoint
returning `{ emailOtp, localPassword, bootstrap, social: { google, microsoft } }`,
so the sign-in UI renders what the instance actually supports instead of
hardcoding buttons.

**Email + password only behind a self-host flag:**

```ts
emailAndPassword: isSelfhostLocalPasswordAuthEnabled()
  ? { enabled: true, autoSignIn: true, minPasswordLength: 12, requireEmailVerification: false }
  : undefined,
```

12 characters, not 8. `requireEmailVerification: false` is correct *here* because
this path exists only for an air-gapped self-host instance that may have no mail
transport at all; on a hosted instance the OTP flow is the verification.

Account linking is deliberately **not** configured. Leaving
`accountLinking`/`trustedProviders` unset keeps the conservative default; turning
it on without understanding provider email verification guarantees is an account
takeover vector.

## Rate limiting

```ts
rateLimit: {
  enabled: !env.E2E_DISABLE_AUTH_RATE_LIMIT,
  window: AUTH_RATE_LIMITS.global.window,
  max: AUTH_RATE_LIMITS.global.max,
  customStorage: createAuthRateLimitStorage(maxWindowMs),
  customRules: {
    "/sign-in/email-otp": { window: 60, max: 5 },
    "/sign-in/email": { window: 60, max: 5 },
    "/sign-up/email": { window: 60, max: 3 },
    "/email-otp/send-verification-otp": { window: 60, max: 5 },
    "/email-otp/verify-email": { window: 60, max: 5 },
    "/forget-password": { window: 60, max: 3 },
    "/reset-password": { window: 60, max: 5 },
  },
}
```

Global 100/min, with per-path rules an order of magnitude tighter on anything
that sends mail or verifies a secret. Custom storage backs onto Redis so the
counter is shared across replicas — see the fail-open tradeoff in SKILL.md.

## Database hooks

Run on both `user.create.before` and `user.update.before`:

- **Validate the timezone ID** with an `Intl.DateTimeFormat` probe, throwing
  `APIError("BAD_REQUEST")` on a bad IANA id. Never persist an unvalidated
  string that a formatter will later choke on.
- **Ensure a display name.** Email OTP and several social providers leave `name`
  blank, and a `notNull` column happily accepts `""` — which surfaces as a blank
  author everywhere. Fall back to the email local part.
- **Normalize preference fields** (trim, length-cap, null-on-empty).

## Request hooks

`hooks.before` — gate paths that must not exist on this deployment shape (e.g.
assert email OTP is permitted, assert a self-host bootstrap sign-up carries the
bootstrap token).

`hooks.after` — **new-device login detection.** On the OTP-verify and
password-sign-in paths only, scan a bounded number of prior sessions, build sets
of known IPs and known `${browser}|${os}` device fingerprints, and if either is
new, dispatch a notification email via the framework's background runner.
Bounded scan, background dispatch, skipped in dev.

## Plugins

Add on demand, cheapest first. Each entry needs a reason:

| Plugin | Reason |
|---|---|
| `bearer()` | Token auth for clients without cookies (CLI, browser extension) |
| `jwt({ disableSettingJwtHeader: true })` | Only for `/jwks`. Header signing off — nothing consumes it, and it costs a jwks read on every session resolution |
| `lastLoginMethod()` | "Last used" hint on the sign-in panel |
| `emailOTP({ sendVerificationOTP })` | Primary sign-in |
| `organization({ ac, roles, membershipLimit, organizationHooks, sendInvitationEmail })` | Tenancy + RBAC |
| `oauthProvider({ ... })` | Only if your app is itself an OAuth authorization server |

`organizationHooks.afterRemoveMember` must revoke the departing member's auth
artifacts inside a transaction. See `references/testing.md` for the lint rule
that keeps that path single.

### Acting as an OAuth authorization server

Needed only when third-party clients (e.g. MCP clients) authenticate against
you. The load-bearing parts:

- `loginPage` / `consentPage` point at frontend routes.
- `clientReference: ({ session }) => session.activeOrganizationId` — bind every
  issued token to a tenant.
- `customAccessTokenClaims: ({ referenceId }) => ({ org_id: referenceId })` —
  and then **require** that claim when verifying. A token without a tenant claim
  must be rejected, not treated as unscoped.
- `postLogin` with a `shouldRedirect` that forces organization selection when a
  resource scope is requested.
- Short access tokens (15 min) because verification is stateless.

Redirect handling: the server-side UI routes move the signed OAuth query string
into the URL **hash** before redirecting to the frontend, so it never leaks via
the `Referer` header. The client then bridges it out of the hash back into the
request body. Worth copying whenever a signed value has to survive a redirect.

## 4. Email transport

```ts
export type EmailTransport = { send(message: EmailMessage): Promise<void> };
```

`EmailMessage.text` is **required**, not optional. HTML-only mail is both a spam
signal and an accessibility failure. Render both from the same template.

Implementations behind the interface (SES, SMTP — `requireTLS` outside dev),
selected once by `EMAIL_PROVIDER` and cached.

**Dev mode short-circuit.** When `isDev`, do not send: log the OTP and stash it
in an in-memory map with a ~5 minute TTL, drained one-shot by a dev-only
endpoint that 404s in production. The frontend prefills the OTP field from it.
This removes the mail-catcher from the local setup entirely.

**Fail loudly when misconfigured.** If not dev and no transport is configured,
OTP send throws `APIError("BAD_REQUEST", { message: "Email sign-in is not
configured for this instance." })` — never a silent no-op that looks like a
delivery delay.
