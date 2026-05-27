---
name: conejo-code
description: Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review), red-green TDD execution, build-fix, deps-check, coding standards, bug-fix learning. Owns the canonical testing doctrine. Use when writing or changing code (backend, logic, APIs, libraries, CLIs).
---

# Conejo-code — active coding

The hands-on coding loop. Philosophy lives in [[conejo]]; this skill is how you execute it.

## The loop (adapted feature stages)

Brainstorm → Plan → Interface → **failing tests** → Implement → Improve tests → Code review.
Full stage notes: `references/feature-stages.md`. UI stages (design/UIUX-review) and any
visual work are owned by [[conejo-frontend]].

## Testing — READ FIRST

The universal red-green doctrine is canonical in `references/testing-doctrine.md`.
Backend/logic/CLI/library use `vitest`; UI behavior uses agent-browser click-flows
(see [[conejo-frontend]]). Never implement before a failing test.

## Standards & helpers

- Coding standards: `references/coding-standards.md` (+ `-api-design.md`).
- Dependency hygiene (bun): `references/deps-check.md`.
- Capture bug-fix learnings: `references/bug-fix-learning.md`.
- Strengthen tests after green: `references/auto-improve-tests.md`.
- Optional auto-trigger hooks: `hooks/` — install with `scripts/install-conejo-hooks.sh`.

## Tooling

bun (not npm), vitest (not jest, not `bun test`), vite-plus (`vp`) for build/check. ESM only.
