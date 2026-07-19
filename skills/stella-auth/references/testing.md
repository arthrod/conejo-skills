# Testing and mechanical enforcement

Only test what can actually go wrong — bugs the type system, framework, or
linter would miss. In auth, that list is short, specific, and non-negotiable.

## The tests that must exist

**Cross-tenant isolation.** The single highest-value test in the codebase:

> "membership in one organization does not leak workspace access when queried
> against another organization"

Give it that name. Anyone reading it later must not have to infer the stakes.

**Permission-check ordering.** "permission macro authenticates before checking
permissions" — asserts a 401 for an anonymous caller, not a 403. Leaking
"this route exists and you'd need role X" to an unauthenticated caller is an
information disclosure.

**Membership resolution matrix.** One case per branch of the bounded query:
role-only, member-of-workspace, admin bypass with a client, admin bypass without
a client (must fail), wrong org, no membership.

**Role grant boundaries.** A matrix over roles × statements in the permissions
package. Cheap, pure, and it catches an accidental widening in a role definition
immediately.

**Column grants.** Assert the migrations grant the scoped role every Better Auth
user column. Adding a column without the grant produces a runtime 500 during
session resolution — the worst possible place to discover it.

## Source-text invariants

Some rules cannot be expressed in types, so assert them against the source:

**Every route registration declares `permissions:`.** Walk the route files, parse
the registrations, fail on any state-changing route without a permission
declaration. This is the test that survives contributors who do not know the
convention.

**No bearer credentials in EventSource URLs or query strings.** SSE cannot set
headers, which tempts putting a token in the URL — where it lands in access logs,
proxy logs, and browser history. Assert the absence.

**Auth artifacts teardown goes through one module.** Back it with a custom lint
rule (oxlint plugin) forbidding direct deletes against the session and OAuth
token tables anywhere outside the single revocation helper:

```
.oxlint-plugins/auth-lifecycle.ts
```

A lint rule beats a code-review convention: it fires on the contributor's
machine, before the PR exists.

## RLS tests

Test the policies directly against a real Postgres, connected as the scoped
low-privilege role, asserting that a query without an explicit tenant filter
returns nothing rather than another tenant's rows. RLS that has never been tested
under the scoped role is RLS you do not know is enabled.

Pair these with cross-tenant handler tests that exercise the full stack.

## E2E and fixtures

**Local**: an idempotent seed script provisioning user + organization + member +
session + a Playwright storage-state file. Idempotent matters — developers rerun
it constantly.

**Staging**: mint a session through a secret-guarded smoke endpoint that
provisions a synthetic principal. Give that principal an owner role but
deliberately **no** entitlements and no AI config, so it mirrors a genuinely new
organization. A smoke user with everything pre-configured tests a state no real
user is ever in.

## What not to test

- That Better Auth's own plugins work.
- That a valid session returns 200. The framework guarantees it.
- Handler-level happy paths already constrained by Elysia schemas.

Spend the budget on isolation boundaries instead.
