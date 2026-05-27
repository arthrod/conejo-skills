---
name: conejo-frontend
description: VERY STRICT frontend gate. Enforces the universal red-green doctrine PLUS the UI superset — agent-browser E2E click-flows (NEVER tRPC to assert UI), 24/7 dev server, test isolation, React + Tailwind v4 + shadcn (NO Ant Design). Indexes the design/UI reference skills. Use for any web UI work.
---

# Conejo-frontend — the strict UI gate

Frontend is [[conejo-code]] + the additions below. The red-green discipline is the same;
the vehicle for UI behavior is agent-browser click-flows. Doctrine is canonical in
`../conejo-code/references/testing-doctrine.md` — read it first.

## Hard rules (refuse work that violates these)

1. **Red-green, always.** No UI implementation before a failing agent-browser click-flow.
2. **NEVER use tRPC to assert UI behavior.** tRPC only for tokens/auth/seeding state.
3. **Dev server runs 24/7;** UI checks click against it via agent-browser (see [[browser-test-agent]]).
4. **Test isolation:** each click-flow seeds/resets its own state and cleans up.
5. **Stack:** React + Tailwind v4 + shadcn. **No Ant Design. No Vue.**
6. Consult the relevant reference below before accepting frontend work as done.

## Reference index (folded skills under `refs/`)

- **Design taste & critique:** `refs/refine-distill-frontend`, `refs/ui-ux-pro-max`, `refs/increase-impact-personality-frontend`, `refs/stitch-design-taste`
- **Typography:** `refs/typeset`, `refs/type-mania`
- **Color:** `refs/colorize`
- **UX planning:** `refs/ux-design-brief`
- **shadcn parity:** `refs/shadcn-parity`
- **Routing:** `refs/tanstack-router`, `refs/tanstack-router-best-practices`
- **Generative UI:** `refs/json-render`
- **SEO:** `refs/seo-audit`

Foundational React/styling/layout skills stay top-level: [[react]], [[react-best-practices]],
[[react-composables]], [[tailwind-v4]], [[layout]].
