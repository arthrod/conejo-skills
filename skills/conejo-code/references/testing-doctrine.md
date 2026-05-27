# Testing doctrine (canonical)

One doctrine. The red-green discipline is identical for backend and frontend;
frontend is the same base **plus** the additions in the last section. Only the
*test vehicle* differs per code kind — never the discipline.

## Universal red-green (every change: backend, frontend, CLI, library)

1. Write the failing test first. Run it. Watch it FAIL (red) for the right reason.
2. Write the minimal code to make it pass. Watch it PASS (green).
3. Refactor under green. Commit. No implementation before a failing test — no exceptions.

## Test vehicle by code kind

- **Backend / pure logic / CLI / library →** `vitest` unit/integration tests
  (transforms, Zod/schema validators, reducers, tRPC router output shape, services).
  Fast, no server.
- **Frontend UI behavior →** agent-browser E2E click-flows. The failing test is a
  user action (a click) whose expected on-screen result does not exist yet; implement
  until the click-flow goes green.

A change can need both layers (e.g. a new feature with logic + UI): write both, each red-green.

## Frontend additions (the superset — enforced by conejo-frontend)

1. Keep a dev server running 24/7; UI red-green checks run against it as agent-browser click-flows.
2. NEVER call tRPC to assert UI behavior. tRPC is allowed ONLY to obtain tokens,
   authenticate, or seed/reset state — never as a stand-in for a user action.
3. Test isolation is mandatory: each click-flow seeds/resets its own state (via the
   permitted tRPC seeding) and cleans up. No shared mutable state between flows.
4. Stack: React + Tailwind v4 + shadcn. No Ant Design. No Vue.

## Playwright → agent-browser translation (for adapted shipshape patterns)

- Code-driven selectors → agent-browser role/text clicks ("click the 'Save' button").
- Explicit `await page.waitFor…` → rely on agent-browser's built-in settling; assert on
  visible result, not on timing.
- Page objects → short reusable click-flow descriptions, not classes.
- Retries → fix the flake (isolation/seeding); do not paper over with retries.
