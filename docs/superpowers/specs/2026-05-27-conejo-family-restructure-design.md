# Conejo coding-philosophy skill family — restructure

**Date:** 2026-05-27
**Repo:** `cicero-im/conejo-skills` (the `arthrod-skills` marketplace)
**Branch base:** `main`

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

Codified in **conejo-code** (general) and enforced hard in **conejo-frontend**:

1. **E2E drives the real UI by clicking buttons via `agent-browser`. NEVER call tRPC to exercise behavior under test.**
2. **tRPC is allowed ONLY to obtain tokens, authenticate, or seed/reset state** — never to assert UI behavior.
3. **TDD keeps a dev server running 24/7**; the failing→passing checks are agent-browser E2E click-flows against that server, not tRPC calls.
4. **No Ant Design.** Frontend stack is React + Tailwind v4 + shadcn (per the folded skills). Any antd reference inherited from shipshape is removed; Vue patterns are dropped.
5. **conejo-frontend is "very, very strict":** it refuses tRPC-driven UI tests, refuses antd, requires a running dev server, and requires the relevant design-skill references to be consulted before frontend work is accepted as done.

## shipshape adaptation = content-fold, not plugin-port

`conejo-skills` is a flat **skills** marketplace (no `commands/`/`agents/`/`hooks/` registration). Adapt shipshape *content* into the conejo-* SKILL.md files and their `references/` subfiles; do not port plugin machinery. Mapping:

- `commands/{feature,plan,tdd,build-fix}` + `agents/{planner,tdd-guide,build-error-resolver}` + `skills/{feature-stages,coding-standards,deps-check,bug-fix-learning,auto-improve-tests}` → **conejo-code** (adapted: npm→bun, jest→vitest, build→vite-plus, ESM-only).
- `commands/e2e` + `agents/e2e-runner` + `skills/e2e-testing` → folded into the **doctrine** (agent-browser click-flows), referenced from conejo-code & conejo-frontend.
- `agents/{code-reviewer}` + `commands` review bits → **conejo-merge** (reconciled with existing CodeRabbit engines; existing skeptical/calm flow wins on conflict).
- `agents/uiux-reviewer` + `skills/feature-stages/stage-6-uiux-review` + `react-patterns` → **conejo-frontend** (Figma dependency removed; uses agent-browser).
- **Dropped:** `vue-patterns`, all Ant Design, the Figma integration, README.zh-TW unless trivially kept.

## Frontend-skill consolidation (relocate + dereference)

Move these **18** skill dirs to `skills/conejo-frontend/refs/<skill>/` and **remove them from `marketplace.json`** so only `conejo-frontend` loads at top level; its SKILL.md links to each `refs/<skill>/SKILL.md` with a one-line purpose:

```
refine-distill-frontend, increase-impact-personality-frontend, ui-ux-pro-max,
stitch-design-taste, layout, colorize, typeset, type-mania, ux-design-brief,
react, react-best-practices, react-composables, tailwind-v4, shadcn-parity,
json-render, seo-audit, tanstack-router, tanstack-router-best-practices
```

**Stay top-level (not folded):** `impeccable`, `dogfood`, `dogfood-quirks`, `browser-test-agent` (shared E2E engine, referenced by both conejo-code and conejo-frontend), `i18n-inlang-localization`.

`refs/` is organized in conejo-frontend's index by purpose: design taste, layout, typography, color, react patterns, styling, routing, generative UI, SEO.

## Hook installer (not auto-wired)

shipshape's hooks (`pre-edit-cookbook-check`, `post-stop-bug-fix-learning`) are adapted into `skills/conejo-code/hooks/` as standalone scripts, plus **`scripts/install-conejo-hooks.sh`** — an idempotent installer that merges the hook entries into the user's `~/.claude/settings.json` (or a chosen settings file) on demand, with a `--dry-run` and a clear print of what it will add. Nothing auto-fires until the user runs it.

## Marketplace + deployment

- `marketplace.json`: remove the old `conejo` entry and the 18 folded skills; add `conejo`, `conejo-code`, `conejo-frontend`, `conejo-merge`. Net registered skills: 94 − 1 − 18 + 4 = **79**.
- **Source of truth is the repo.** The four conejo-* `SKILL.md`s are also mirrored to `~/.claude/skills/<name>/SKILL.md` for immediate local use (as done previously). The 18 folded skills are removed from top-level `~/.claude/skills` via the same sync so they stop loading; a `scripts/sync-to-claude.sh` performs this mirror+prune idempotently. (Symlink-vs-realdir nuance in `~/.claude/skills` is handled by the sync script; the repo remains canonical.)

## Delivery — stacked PRs (each over the previous), merged with the documented stacked method

1. **conejo-merge** — move current `conejo` content verbatim into `skills/conejo-merge/`, fix frontmatter + internal self-references; register in marketplace; leave old `conejo` temporarily.
2. **conejo (philosophy)** — rewrite `skills/conejo/SKILL.md` as the thin philosophy/dispatcher; update its marketplace description.
3. **conejo-code** — create from adapted shipshape content + the TS testing doctrine + `hooks/` + `scripts/install-conejo-hooks.sh`.
4. **conejo-frontend + fold** — create the strict skill; `git mv` the 18 skills into `refs/`; build the reference index; deregister the 18 in marketplace.
5. **sync + docs** — `scripts/sync-to-claude.sh`, README family-map update, marketplace count/version bump.

## Risks

- **`~/.claude` ↔ repo ↔ `~/.agents` deployment** is not a uniform copy (some skills are symlinks). Mitigation: the repo is canonical; `sync-to-claude.sh` handles mirror+prune and is the only thing that touches `~/.claude`.
- **Reference rot:** folding 18 skills under `refs/` means any external doc that named them as top-level skills breaks. Mitigation: conejo-frontend index lists all 18; a grep for the old names across the repo updates stragglers.
- **Doctrine vs. existing skills conflict:** conejo-code's TDD doctrine must not contradict the existing `test-driven-development` / `verification-before-completion` skills — conejo references them and adds the agent-browser/tRPC specifics rather than restating.
