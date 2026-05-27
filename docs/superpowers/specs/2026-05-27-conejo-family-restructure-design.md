# Conejo coding-philosophy skill family — restructure

**Date:** 2026-05-27
**Repo:** `cicero-im/conejo-skills` (the `arthrod-skills` marketplace)
**Branch base:** `main`
**Review:** externally reviewed by GLM-5.1 (opencode, zai-coding-plan) — verdict GO-WITH-CHANGES; this revision folds in C1 (keep `react`/`layout` foundational), C2 (layered unit+E2E testing), I1–I5, and minors M1–M3/M5/M6.

## Problem / goal

Today `skills/conejo/SKILL.md` is a 1035-line catch-all bundling four unrelated engines (skeptical PR hunt, calm-implement, CodeRabbit-review, Autofix, PR-triage). Separately, the `arthrod/muki-ai-plugins` `shipshape-skills` plugin holds a disciplined dev workflow worth absorbing (TDD, feature-stages, planning, code/UIUX review, E2E) — but it's npm/React+Vue/Ant-Design/Playwright-flavored and ships as plugin machinery, not skills.

Make **`conejo` our general coding philosophy** and split the work into a focused family, fold in the adapted shipshape content, codify a strict TypeScript/visual testing doctrine, and consolidate the frontend skills so they don't flood context. The Figma plugin (`figma-visual-reviewer`) is **not** copied.

## The family (four registered skills)

| Skill | Role |
|---|---|
| **conejo** | Umbrella **coding philosophy**: TDD red-green always, test-always (no exceptions), stacked PRs (branch-over-branch, PR often), brainstorm-before-build, systematic-debugging-first, verification-before-completion (evidence before claims). Thin dispatcher pointing to the other three and to existing process skills. |
| **conejo-code** | **Active coding** loop + mechanics: feature-stages (brainstorm→plan→interface→tests→implement→improve-tests→review), TDD execution, build-fix, deps-check, coding-standards, bug-fix-learning, auto-improve-tests. Carries the strict TS testing doctrine. |
| **conejo-frontend** | **Very strict** frontend gate + a reference index (`refs/`) into the folded frontend skills. Enforces the visual testing doctrine and stack rules. |
| **conejo-merge** | **Calm, slow PR approach**: the entire current `conejo` content (skeptical Phases 1-4, calm Phase 5, CodeRabbit-review engine, Autofix, PR-triage, the stacked-merge method, CodeRabbit auto-request rule). |

`conejo`'s frontmatter `description` becomes the philosophy/dispatcher summary; `conejo-merge` inherits the current PR-handling description.

## Strict TypeScript / visual testing doctrine

**One doctrine, universal red-green base, frontend is a superset.** The strict TDD red-green discipline is **identical and mandatory for backend and frontend alike** — there is no "frontend TDD" vs "backend TDD." Frontend is exactly the backend doctrine **plus** additional implementations (a 24/7 dev server and agent-browser E2E click-flows as the red-green vehicle for UI behavior). The discipline never changes; only the *vehicle* for a given test layer differs.

**Universal red-green (applies to every change — backend, frontend, CLI, library):**
1. Write the failing test **first**; run it; **watch it fail (red)** for the right reason.
2. Write the minimal code to make it pass; **watch it pass (green)**.
3. Refactor under green. Commit. No implementation before a failing test — no exceptions (mirrors the existing `test-driven-development` skill, which conejo links to rather than restating).

**Canonical location (resolves drift, per review I1):** authored **once** in `skills/conejo-code/references/testing-doctrine.md`. `conejo` states the philosophy and links here; `conejo-code` owns this base doctrine; `conejo-frontend` links here and adds **only** the frontend-specific additions below + the enforcement posture — never a second copy.

**Test vehicle by code kind (per review C2 — the doctrine does NOT ban unit tests):**
- **Backend / pure logic / CLI / library:** the red-green vehicle is **`vitest`** unit/integration tests (transforms, schema/Zod validators, reducers, tRPC router shape, services) — fast, no server.
- **Frontend UI behavior:** the red-green vehicle is **agent-browser E2E click-flows** — the failing test is a user action (click) whose expected on-screen result doesn't exist yet, then you implement until the click-flow goes green.

**Additional frontend implementations (the superset — `conejo-frontend`):**
1. **Keep a dev server running 24/7**; UI red-green checks run against it as agent-browser click-flows. (Pure-logic units still run serverless via vitest, same as backend.)
2. **NEVER call tRPC to assert UI behavior.** tRPC is permitted **only** to obtain tokens, authenticate, or seed/reset state — never as a stand-in for a user action.
3. **Test isolation is mandatory** for E2E: each click-flow seeds/resets its own state (via permitted tRPC seeding) and cleans up — no shared mutable state.
4. **No Ant Design.** Stack is React + Tailwind v4 + shadcn; antd inherited from shipshape is removed, Vue patterns dropped.
5. **conejo-frontend is "very, very strict":** it enforces the universal red-green base AND refuses tRPC-driven UI assertions, refuses antd, requires the 24/7 dev server for UI work, requires test isolation, and requires the relevant design-skill references before frontend work is accepted as done.

## shipshape adaptation = content-fold, not plugin-port

`conejo-skills` is a flat **skills** marketplace (no `commands/`/`agents/`/`hooks/` registration). Adapt shipshape *content* into the conejo-* SKILL.md files and their `references/` subfiles; do not port plugin machinery. Mapping:

- `commands/{feature,plan,tdd,build-fix}` + `agents/{planner,tdd-guide,build-error-resolver}` + `skills/{feature-stages,coding-standards,deps-check,bug-fix-learning,auto-improve-tests}` → **conejo-code** (adapted: npm→bun, jest→vitest, build→vite-plus, ESM-only).
- `commands/e2e` + `agents/e2e-runner` + `skills/e2e-testing` → folded into the **doctrine** (agent-browser click-flows), referenced from conejo-code & conejo-frontend.
- `agents/{code-reviewer}` + `commands` review bits → **conejo-merge** (reconciled with existing CodeRabbit engines; existing skeptical/calm flow wins on conflict).
- `agents/uiux-reviewer` + `skills/feature-stages/stage-6-uiux-review` + `react-patterns` → **conejo-frontend** (Figma dependency removed; uses agent-browser).
- **Dropped:** `vue-patterns`, all Ant Design, the Figma integration, README.zh-TW unless trivially kept.
- **Test runner (per review M1):** standardize on **`vitest`** (the stack's runner, matching docx-validate); `bun test` is not used — state this explicitly so adapted content doesn't mix runners.
- **E2E pattern adaptation (per review M2):** shipshape's E2E was Playwright (code-driven page objects/selectors/waits). Since agent-browser is CLI/natural-language-driven, `testing-doctrine.md` includes a short "Playwright→agent-browser" translation note (selectors→role/text clicks, explicit waits→agent-browser's built-in waits, retries/isolation) rather than assuming a 1:1 port.
- **ESM-only (per review M3):** any CJS patterns inherited from shipshape (`require`, `module.exports`) are converted to ESM during the fold; the conversion is mechanical and called out in the conejo-code PR.

## Frontend-skill consolidation (relocate + dereference)

A cross-reference audit (per review C1/I4) determined which skills are safe to fold. **`react` (14 inbound refs from better-auth*, llm-chat-sdks, zanahoria-*, etc.) and `layout` (15 inbound from rust-author, val-town, pi-*, python-code-review, etc.) are foundational, not frontend-design skills — folding them would break ~29 cross-referencing skills, so they stay top-level.** `tailwind-v4`, `react-best-practices`, and `react-composables` stay with them as the foundational React/styling set.

Move these **13** skill dirs to `skills/conejo-frontend/refs/<skill>/` and **remove them from `marketplace.json`** so only `conejo-frontend` loads at top level; its SKILL.md links to each `refs/<skill>/SKILL.md` with a one-line purpose:

```
refine-distill-frontend, increase-impact-personality-frontend, ui-ux-pro-max,
stitch-design-taste, colorize, typeset, type-mania, ux-design-brief,
shadcn-parity, json-render, seo-audit, tanstack-router, tanstack-router-best-practices
```

**Cross-ref migration (required, per review I4):** of the 13, six (`ui-ux-pro-max`, `stitch-design-taste`, `colorize`, `typeset`, `ux-design-brief`, `shadcn-parity`) are referenced by exactly two staying skills — `adapt` and `impeccable`. The fold PR updates those two files' links to the new `refs/` paths. The other seven have **0** inbound refs from staying skills. No other repo files reference the 13 (verified by grep).

**Stay top-level (not folded):** `react`, `react-best-practices`, `react-composables`, `layout`, `tailwind-v4` (foundational), plus `impeccable`, `dogfood`, `dogfood-quirks`, `browser-test-agent` (shared E2E engine), `i18n-inlang-localization`.

`refs/` is organized in conejo-frontend's index by purpose: design taste, typography, color, styling overrides, routing, generative UI, SEO.

## Hook installer (not auto-wired)

shipshape's hooks (`pre-edit-cookbook-check`, `post-stop-bug-fix-learning`) are adapted into `skills/conejo-code/hooks/` as standalone scripts, plus **`scripts/install-conejo-hooks.sh`** — an idempotent installer that merges the hook entries into the user's `~/.claude/settings.json` (or a chosen settings file) on demand, with a `--dry-run` and a clear print of what it will add. Nothing auto-fires until the user runs it.

## Marketplace + deployment

- `marketplace.json`: remove the old `conejo` entry and the 13 folded skills; add `conejo`, `conejo-code`, `conejo-frontend`, `conejo-merge`. Net registered skills: 94 − 1 − 13 + 4 = **84**.
- **Source of truth is the repo.** The four conejo-* `SKILL.md`s are also mirrored to `~/.claude/skills/<name>/SKILL.md` for immediate local use (as done previously). The 13 folded skills are removed from top-level `~/.claude/skills` via the same sync so they stop loading; a `scripts/sync-to-claude.sh` performs this mirror+prune idempotently.
- **Safe pruning (per review I5):** before deleting any `~/.claude/skills/<x>`, the sync script checks whether the target is a symlink (safe to remove) or a real directory; if real, it diffs against the repo and **refuses to prune / warns** on local modifications rather than destroying work. `--dry-run` prints the full plan.
- **Other skill roots (per review M5):** the same machine also has `~/.agents/skills`, `~/.opencode/skills`, `~/.config/opencode/skills`. The sync script targets `~/.claude/skills` only by default but takes a `--root <dir>` flag so the prune/mirror can be repeated for the others if they shadow the folded names.

## Delivery — stacked PRs (each over the previous), merged with the documented stacked method

1. **conejo-merge** — move current `conejo` content verbatim into `skills/conejo-merge/`, fix frontmatter + internal self-references; register in marketplace; leave old `conejo` temporarily.
2. **conejo (philosophy)** — rewrite `skills/conejo/SKILL.md` as the thin philosophy/dispatcher; update its marketplace description.
3. **conejo-code** — create from adapted shipshape content + the TS testing doctrine + `hooks/` + `scripts/install-conejo-hooks.sh`.
4. **conejo-frontend + fold** — create the strict skill; **pilot first (per review I3):** `git mv` ONE zero-inbound skill (`seo-audit`) into `refs/`, register the loader-resolution expectation, and confirm conejo-frontend can still link/resolve it before moving the rest; then `git mv` the remaining 12 into `refs/`, update the `adapt` + `impeccable` cross-refs, build the reference index, and deregister the 13 in marketplace.
5. **sync + docs** — `scripts/sync-to-claude.sh` (safe-prune), README family-map update, marketplace count/version bump.

## Risks

- **Skill-loader resolution (review I3, highest mechanism risk):** it is not documented whether the loader resolves a referenced skill by `marketplace.json` registration, by `skills/<name>/` directory scan, or by path. If it scans top-level dirs, skills under `refs/` become unresolvable. Mitigation: the PR-4 **pilot** moves one skill first and verifies resolution before bulk-moving; if resolution breaks, fall back to "reference-only" (leave dirs in place, just deregister) for the affected skills.
- **`~/.claude` ↔ repo ↔ `~/.agents`/`~/.opencode` deployment** is not a uniform copy (some entries are symlinks). Mitigation: the repo is canonical; `sync-to-claude.sh` does safe mirror+prune (symlink-aware, refuses to delete locally-modified real dirs) and is the only thing that touches the deployed roots.
- **Reference rot:** folding 13 skills means inbound refs break. Mitigation: audit shows the only inbound refs from staying skills are `adapt` + `impeccable` (six skills), updated in the fold PR; the conejo-frontend index lists all 13; a final grep confirms no stragglers.
- **Foundational mis-fold (review C1):** `react` and `layout` are used well beyond frontend — kept top-level by decision above.
- **Doctrine vs. existing skills conflict:** conejo's philosophy must not contradict the existing `test-driven-development` / `verification-before-completion` / `systematic-debugging` skills. Note these are **not currently referenced** by conejo (verified) — conejo will newly link to them and add the agent-browser/tRPC specifics rather than restating.
- **conejo-merge monolith (review M6):** PR 1 moves the 1035-line content verbatim; an internal refactor of conejo-merge is explicitly **out of scope** for this restructure and left as a follow-up.
