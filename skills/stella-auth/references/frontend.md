# Frontend: client, routes, guards

Step 7. These are UX, not security. Every guard here has a server-side
counterpart that does the real enforcement.

## Mounting on Elysia

```ts
app
  .use(cors({ origin: frontendOrigins(...), credentials: true, exposeHeaders: ["set-auth-token"] }))
  .use(authUiRoute)         // server-side redirects into the SPA
  .use(authMetadataRoute)   // .well-known discovery + capabilities
  .mount(getAuth().handler) // Better Auth as a WinterCG handler
```

`.mount()` takes the standard fetch handler directly. CORS must mirror the same
origin list the auth config trusts — drift between `trustedOrigins` and the CORS
origin is a top-three cause of "cookies not setting".

Discovery endpoints to expose when acting as an authorization server:
`/.well-known/oauth-authorization-server`, the path-suffixed variant for the auth
base path, and `/.well-known/openid-configuration`, each with an OPTIONS
preflight.

## The auth client

```ts
export const authClient = createAuthClient({
  baseURL: env.VITE_API_URL,
  fetchOptions: {
    headers: {
      get "Accept-Language"() { return useI18nStore.getState().lang; },
    },
    onRequest: withOauthQueryFromHash,
    onError: ({ response }) => {
      if (response.status === HTTP_TOO_MANY_REQUESTS) toast(/* ... */);
    },
  },
  plugins: [
    emailOTPClient(),
    lastLoginMethodClient(),
    organizationClient({ ac, roles }),
    inferAdditionalFields({ user: { preferredName, timezoneId, wordEditShortcut } }),
    oauthProviderClient(),
  ],
});
```

Three details worth copying:

**`Accept-Language` as a getter**, not a captured value. Otherwise the language
at module-init time is sent forever, and OTP emails arrive in the wrong language
after a user switches.

**`onRequest` hash bridging.** The server redirect parks the signed OAuth query
in the URL hash; this hook lifts it back into the JSON body on non-GET/DELETE
requests. Together these keep the signed value out of the `Referer` header.

**429 handling at the client level**, so every call site inherits the rate-limit
toast without repeating it.

`organizationClient({ ac, roles })` imports the *same* access-control package the
server uses — one definition of roles across the stack, so a UI that hides a
button and a server that returns 403 can never disagree.

## Revocation tokens as branded types

Session tokens surfaced for revocation are wrapped in an opaque branded type
rather than passed as bare strings:

```ts
export const listAuthSessions = async (): Promise<AuthSession[]> => /* ... */;
export const revokeAuthSession = async ({ token }: { token: SessionRevocationToken }) => /* ... */;
```

This makes it structurally impossible to log, render, or send a revocation token
somewhere it does not belong. Prefer this over a discipline-based rule anywhere a
secret string crosses component boundaries.

## Routes

| Route | Purpose | Guard |
|---|---|---|
| `/auth` (layout) | Loads shared auth context | `beforeLoad: loadAuthContext(queryClient)` |
| `/auth` (index) | Sign-in panel | Signed in → OAuth post-login href, else `/auth/organization` |
| `/auth/otp` | OTP entry | Signed in → `/auth/organization`; loader fetches the dev OTP |
| `/auth/organization` | Tenant selection | No session → `/auth` (preserving the hash); active org present and not an OAuth post-login → forward to `redirectTo` |
| `/auth/accept-invitation/$invitationId` | Invitation accept/reject + `setActive` | — |
| `/auth/error` | Error surface | — |
| `/consent` | OAuth consent screen | — |
| `/_protected` | **Main app guard** | No session/user → `/auth?redirectTo=…`; no active org → `/auth/organization` |

Two-step sign-in (authenticate, then choose tenant) is inherent to putting the
active organization on the session. Do not try to collapse it.

`validateSearch` with a `normalizeRedirectTo` helper on any route accepting a
`redirectTo`. An unvalidated `redirectTo` is an open redirect.

## Guard details

The protected-route guard **awaits** the role prefetch before rendering, and
fires non-blocking prefetches for everything else. Resolving the role mid-mount
triggers React's not-yet-mounted warning, which route-smoke e2e treats as a
failure. Await what the first paint needs; fire-and-forget the rest.

Shared auth context reads two queries, both with a route-level stale time:

```ts
sessionOptions  // authClient.getSession()
roleOptions     // authClient.organization.getActiveMemberRole()
```

Both `queryFn`s **dynamically import** the auth client module, keeping Better
Auth and its plugins out of the initial bundle — it is only needed once a route
actually asks for a session.

## Sign-in panel

One `sign-in-panel.tsx` rendering only the methods the instance reports via
`/auth/capabilities`, reused inside a dialog for re-authentication. Extract the
branching into a `sign-in-panel.logic.ts` so the method-selection rules are unit
testable without mounting React.

After a successful OTP sign-in, immediately push the browser timezone:

```ts
await authClient.updateUser({ timezoneId: browserTimezone });
```

Capture environment facts at the one moment you are certain a real user is
present.
