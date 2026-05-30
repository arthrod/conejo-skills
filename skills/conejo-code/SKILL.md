---
name: conejo-code
description: Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review→loop), red-green TDD execution, build-fix, deps-check, coding standards, bug-fix learning. Owns the canonical testing doctrine. Use when writing or changing code (backend, logic, APIs, libraries, CLIs).
---

# Conejo-code — active coding

The hands-on coding loop. Philosophy lives in [[conejo]]; this skill is how you execute it. Relentless, disciplined, experiment-driven and detail-oriented coding practice. ALWAYS set a timer to (1) wait for the user, (2) wait for Claude agents, (3) Claude or any other tool or (4) wait for opencode or forge agents. NEVER expect that you will be awaken by the response of any of these. YOU MUST BE FULLY AUTONOMOUS AND IMPLEMENT THE ORIGINAL PLAN INFERRING THE BEST ALTERNATIVES TO ENSURE IT WORKS.

## The loop (adapted feature stages)

- Brainstorm (Specs) → run "opencode run $PROMPT --model zai-coding-plan/glm-5.1 --dangerously-skip-permissions --dir  path/to/this/dir" to review your specs → Plan "opencode run $PROMPT --model deepseek/deepseek-v4-pro --dangerously-skip-permissions --dir  path/to/this/dir" to review your plan (glm-5.1 is smarter but slow, deepseek is a bit faster) → Interface → "opencode run $PROMPT --model deepseek/deepseek-v4-pro --dangerously-skip-permissions --dir  path/to/a/clone/of/this/dir" to create tests **failing tests** → "opencode run $PROMPT --model deepseek/deepseek-v4-pro --dangerously-skip-permissions --dir  path/to/a/clone/of/this/dir" to Implement → Improve tests → Code review  → (loop).
- Full stage notes: `references/feature-stages.md`. UI stages (design/UIUX-review) and any
visual work are owned by [[conejo-frontend]].
- Attention! Don't be afraid of sending several agents: split the tasks as much as possible. 
- PR over PR ALWAYS. Push. After it is at Github, clean their mess.
- PRESERVE your context no matter what! Send these other agents first, so we can have different perspectives, but if you need to do the work, send your agents. Don't pollute your context.

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
