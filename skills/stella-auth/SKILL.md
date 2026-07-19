---
name: stella-auth
description: 'Reproduce Stella''s multi-tenant authentication methodology: Better Auth on Elysia/Bun with Drizzle+Postgres, passwordless email OTP, organization-scoped RBAC via statement access control, Postgres RLS as the last line of defence, and per-request-memoized Elysia macros. Use when building auth for a multi-tenant B2B app, adding org/workspace scoping to an existing Better Auth setup, or reviewing whether an authorization stack actually isolates tenants.'
---

# Stella Auth Methodology

How Stella builds authentication and authorization. This is a *methodology*,
not a config dump: the ordering, the layering, and the reasons behind each
choice are the transferable parts.

Target stack: **Better Auth + Elysia (Bun) + Drizzle + PostgreSQL + React/TanStack
Router**. Adapt the transport layer freely; do not adapt away the three
authorization layers.

## The central idea: three layers, no single point of trust

Authorization is enforced three times, independently, at descending levels of
trust:

| Layer | Where | Answers | Failure mode it catches |
|---|---|---|---|
| 1. **Authentication** | Elysia macro (`validateAuth`) | Who is this request? | Missing/expired session |
| 2. **Authorization** | Statement access control (`roles[role].authorize(...)`) | May this role do this? | Under-privileged actor calling a privileged route |
| 3. **Data scoping** | Postgres RLS via a scoped connection | May this tenant see this row? | A handler that forgot its `WHERE organizationId` |

Layer 3 is the one people skip. Do not skip it. Layers 1 and 2 are application
code and will eventually have a hole in them; RLS is the backstop that turns a
missing filter from a cross-tenant data leak into an empty result set.

**Ownership IDs never come from the request body or query string.**
`organizationId` comes from `session.activeOrganizationId`; `workspaceId` comes
from a path param that has been proved against a membership row *in this
request*. A body-supplied tenant ID is a vulnerability, not a convenience.

## Tenancy model

Two nested scopes, and you should decide which you need before writing code:

- **Organization** = the tenant. Maps to Better Auth's `organization` plugin.
  Carries billing, settings, members, roles.
- **Workspace** = a sub-scope inside an organization (a matter, project, client
  engagement). Has its own membership table (`workspaceMembers`) so a member of
  the org is not automatically a member of every workspace.

The active organization lives on the session (`session.activeOrganizationId`),
which is why sign-in is a **two-step flow**: authenticate, then select/confirm
an organization before entering the app. Build `/auth/organization` as a real
route, not an afterthought.

Admin bypass: `owner` and `admin` may reach workspaces they are not members of,
but *only* when the workspace has a client attached. Encode that as an explicit
`ADMIN_BYPASS_ROLES` constant in the join condition, never as an early `if`
that skips the query.

## Build order

Work in this order. Each step depends on the previous one being correct.

1. **Env schema first.** Validate auth env vars at boot with Valibot, including
   cross-field rules. An instance that starts with a 12-character
   `BETTER_AUTH_SECRET` is worse than one that refuses to start.
2. **Schema + RLS policies together.** Write the Better Auth tables and their
   row-level-security policies in the same commit. Adding RLS later means
   auditing every query you already wrote.
3. **The auth module as a lazy singleton.** `betterAuth()` eagerly resolves the
   Drizzle adapter, which touches the DB module. Wrap it in `createAuth()` /
   `getAuth()` or you get a temporal-dead-zone error the moment a test runner
   evaluates modules in a different order.
4. **Email transport abstraction**, before any plugin that sends mail.
5. **Plugins**, cheapest first: `emailOTP` → `organization` → the rest.
6. **The macro stack** (`sessionAuthMacro` → `authMacro` → `permissionMacro` →
   `workspaceAccessMacro`).
7. **Frontend route guards** last — they are UX, not security.

Detailed configuration for steps 1–5: `references/server-config.md`.
Detailed macro + permission wiring for step 6: `references/authorization.md`.
Frontend for step 7: `references/frontend.md`.
What to test and what to enforce with lint: `references/testing.md`.

## Non-negotiables

These are the decisions that cost real debugging time to arrive at. Copy them
verbatim; deviate only with a written reason.

**Memoize the auth resolve per request.** Elysia expands a macro property into
an independent `resolve` hook at *every* distinct call site — a `.guard()`, a
`.group()`, and a per-route `permissions` on the same route run the resolve
three times, each re-running the session, role, and settings lookups. Cache the
in-flight promise in a `WeakMap<Request, Promise<T>>`. Key on the `Request`
instance: that gives zero cross-request caching (a revoked session is re-checked
on the very next request) and automatic cleanup. This is a correctness
requirement, not an optimization.

**Bound every membership query.** Request-time authorization must never expand a
user's full access set. Two queries, both `.limit(1)`: one for role-only, one
that LEFT JOINs the workspace under an `exists(...)` membership check. Anything
that scales with the number of workspaces a user can see will fall over at
enterprise size.

**Let the auth resolve's return type stay inferred.** Annotating it collapses the
generics on the scoped-DB handles to their default constraint and silently
widens what handlers can query.

**Reuse the already-resolved role for permission checks.** Do not ask Better
Auth to re-read the session to check a permission. The permission macro sets
`validateAuth: true`, reads the resolved `memberRole` off the context, and calls
the local role map. One session read per request.

**Set `body: t.Object({})` on any macro that also extends the body.** Without it,
stacking two macros drops the first one's body extension from the merged schema.

**Sessions in the database.** `storeSessionInDatabase: true` with a 7-day expiry
and a 1-day update age. Stateless-only sessions cannot be revoked, and
revocation is a compliance requirement in this domain.

**Every state-changing route declares its permissions.** Enforce it with a test
that greps route registrations, not with review discipline.

**Route auth-artifact teardown through one helper.** Removing a member must
revoke their sessions *and* OAuth access/refresh tokens. Put that in a single
module and add a custom lint rule forbidding direct deletes against those tables
anywhere else.

## Two accepted risks to decide on consciously

Copying this methodology means inheriting these. Make the call knowingly.

**Stateless token revocation lag.** OAuth access tokens are verified via JWKS
without a DB round-trip, so a revoked client's already-issued token stays valid
until it expires (15 min). Checking the DB per request closes the window at
hot-path cost. Stella accepted the lag; a shorter TTL is the cheap mitigation.

**Rate-limit storage fails open.** Redis is the shared counter across API
replicas; on timeout or unreachability it degrades to a per-process `Map`. A
Redis outage must not hard-lock sign-in — but during one, an attacker gets up to
N× the configured OTP limit with N replicas. If your threat model cannot accept
that, fail closed and accept the availability hit.

## Anti-patterns

- Taking `organizationId` or `workspaceId` from the request body.
- A single `isAdmin` boolean instead of a role with statement-based grants.
- Checking permissions inside the handler body rather than in a `beforeHandle`
  that runs before any work.
- Optional chaining (`?.`) over relations that are structural invariants — use
  an explicit panic so the invariant break is loud.
- Adding a `passkey`/`twoFactor`/`admin` plugin "for completeness". Every plugin
  is tables, migrations, and attack surface. Add on demand.
- Frontend guards as the only guard. `beforeLoad` redirects are UX.
