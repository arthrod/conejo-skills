# arthrod's Skill Registry

**81 skills** — last sync `2026-11-13`. **v3.3.0**

Major restructure: families collapsed (Pi → 2 skills, Pydantic AI → 1 with `references/`,
Rust → `rust-author` + `rust-review`, Better Auth slimmed, design dials folded into `impeccable`),
new combined skills (`conejo` absorbs code-review + autofix + pr-triage-gh, `marimo` absorbs 4
marimo skills, `ml-gpu-training` absorbs CUDA setup). All design tools include a Stitch-first
mandate (`STITCH-DESIGN.md` in each design-skill folder). 13 design/UI skills folded into
`conejo-frontend/refs/` as reference docs.

**v3.3.0 (2026-11-06) — the development-system release.** The 15 process-discipline skills
are re-vendored from [obra/superpowers v7.0.2](https://github.com/obra/superpowers/tree/v7.0.2)
(`22f0b46`) with upstream text kept verbatim and this repo's rules appended in a
`<!-- conejo:start --> … <!-- conejo:end -->` block (see
[Development system rules](#development-system-rules-arthur-2026-11-06)). Three doctrines are
now canonical in `conejo-code/references/`: `agent-dispatch.md` (other-corpus model CLIs —
how to list and select models for pi, crush, codex, grok, cline, octo), `acceptance-criteria.md`
(every plan task carries acceptance criteria with an independent measurer) and
`stacked-prs-and-ci.md` (stacked PRs via `gh stack`; CI/CD wait only on the last task; PR
comments one by one). House stack switched to pnpm / uv / pyrefly / oxlint / oxfmt / vite /
vitest / Astro / cargo-nextest. Marketplace manifest reconciled with what is on disk.

## Conejo coding-philosophy family

The `conejo-*` skills form a tightly coupled coding + PR workflow. They share four
doctrines authored once inside `conejo-code/references/` and route to each other:

- `testing-doctrine.md` — universal red-green TDD.
- `agent-dispatch.md` — the Warren Protocol: dispatch work to **other-corpus** model CLIs
  (pi → crush → codex → grok → cline → octo → subagents) to preserve context and get a
  different corpus's opinion; the reviewer is never the author's model. Lists, per tool, how
  to see its models and how to select one.
- `acceptance-criteria.md` — every plan task has acceptance criteria, each with an
  independent measurer (a command, probe, click-flow, diff or metric that proves the behavior
  from outside the code). Red before, green after; the reviewer runs it.
- `stacked-prs-and-ci.md` — stacked PRs via `gh stack` (one plan = one stack, one task = one
  layer, never hand-rebase); wait for CI/CD only on the plan's last task; PR comments answered
  one by one, ledger reconciled.

| Skill | Role |
|---|---|
| **`conejo`** | Universal dispatcher/philosophy — enforces red-green TDD, acceptance criteria with independent measurers on every task, stacked PRs driven by `gh stack` (no hand rebases of the chain), evidence-before-claims, other-corpus agent dispatch, CI/CD wait only on the last task, the hidden-gems review doctrine, one-by-one PR replies and the no-batch-review rule. Carries the house stack preference. Routes work to the specialised siblings below. |
| **`conejo-code`** | Active coding loop. Holds the four canonical doctrines: `references/testing-doctrine.md` (red-green-refactor, no green-without-red, no implementation without a failing test), `references/agent-dispatch.md` (pi/crush/codex/grok/cline/octo dispatch ladder with model listing + selection commands, adversarial review prompts, model preferences), `references/acceptance-criteria.md` (independent measurers, RED/GREEN, ledger format) and `references/stacked-prs-and-ci.md` (`gh stack` command set, CI-only-on-last-task rule). |
| **`conejo-frontend`** | VERY STRICT UI gate. Mandates agent-browser E2E click-flows for every UI assertion; forbids tRPC calls to assert UI state (allowed only for auth/seeding). Requires a 24/7 dev server, React + Tailwind v4 + shadcn/ui; rejects Ant Design. Mandatory screenshot + browser-console + design-critique loop before any visible change counts as done. 13 design/UI skills live under `skills/conejo-frontend/refs/` as reference docs reached via its index — they are **not** standalone registered skills. |
| **`conejo-merge`** | Calm-implement PR handler: **one comment at a time, without exception** — gate each comment individually (batch review is forbidden; the verdict ledger must reconcile), group into tasks, test/install/ship, reply with state changes. Hidden-gems doctrine: different bots = different corpora, so weird nits get more scrutiny, not less. Deep engines live under `skills/conejo-merge/refs/` (CodeRabbit CLI engine, autofix, PR triage incl. the `gh stack` stacked-PR workflow and merge order, proud-zanahoria). |
| **`conejo-legal`** | Single-issue US doctrinal legal research run with PR-review discipline: source-audited OKF `legal_issue` bundle (SKOS digest, source/snippet ledger), same hidden-gems and one-by-one verification rules as the code family. |
| **`conejo-debug`** | Skeptical investigator & autonomous deep work: hunt PRs like crime scenes, interrogate CodeRabbit plans, systematic debugging protocol with multi-agent second opinions, strict TDD fixes. Slow, powerful, one clue at a time. |

> **Foundational top-level skills** — `react`, `react-best-practices`, `react-composables`
> and `tailwind-v4` remain registered as independent top-level skills because they are used
> well beyond frontend work and are referenced by non-frontend skill families. `layout` was
> folded into `conejo-frontend/refs/` and `impeccable` (commit 9a0b1f6).

### Helper scripts

| Script | Purpose |
|---|---|
| `scripts/install-conejo-hooks.sh` | Opt-in hook installer: idempotently merges two **Claude Code** hooks into a `settings.json` (default `~/.claude/settings.json`, override with `--settings`) — a `PreToolUse(Edit|Write)` cookbook-check and a `Stop` bug-fix-learning hook. Supports `--dry-run`. Does **not** touch git hooks. |
| `scripts/sync-to-claude.sh` | Mirrors the `conejo-*` skills to `~/.claude/skills` and prunes the 13 folded design skills that now live inside `conejo-frontend/refs/`. Symlink-aware, refuses to delete locally-modified directories, supports `--dry-run` and `--root <path>`. |
| `scripts/update-skills.sh` | **Default (publish):** refreshes vendored skills from their original upstream remotes (via `scripts/update-vendored.sh`), then copies `./skills/` → `~/.agents/skills/` (overwrite) and symlinks `~/.claude/skills/<name>` → `../../.agents/skills/<name>`. `--reverse` flips direction: `~/.claude/skills/` → `./skills/` (additive, or `--yolo` to wipe). `--skip-vendored` skips the upstream refresh. Step 3b also symlinks every skill into each other agent's skills dir that exists (`~/.pi/agent/skills`, `~/.codex/skills`, `~/.config/crush/skills`, `~/.grok/skills`, `~/.cline/skills`, `~/.gemini/skills`, `~/.config/agents/skills`; override with `AGENT_DIRS="…"`) so pi/codex/crush/grok/cline see the same skills as Claude. `DRY_RUN=1` everywhere. |
| `scripts/update-vendored.sh` | Per-skill upstream refresh. Reads `scripts/vendored-sources.tsv` and re-fetches each `IDENTICAL`/`MERE-COPY` skill's `SKILL.md` (+ `references/`) from `github.com/<repo>` via `gh api`. Skips `CUSTOMIZED` and `SUPERPOWERS` rows, warns on `LIGHT-EDIT` unless `FORCE=1`. Preserves `<!-- cross-ref -->` and `<!-- conejo -->` blocks. |
| `scripts/refresh-superpowers.sh` | Whole-directory refresh of the 15 superpowers skills: pulls obra/superpowers into the git-ignored `./superpowers/` clone (`REF=<tag>` to pin), replaces each `skills/<name>/` (scripts, prompts, references and all), re-appends the vendored footer and the skill's `<!-- conejo -->` block. `DRY_RUN=1`; optional skill-name arguments for a subset. |

## Development system rules (Arthur, 2026-11-06)

Five rules, enforced from the `conejo` non-negotiables and from the `conejo` block of every
vendored superpowers skill. Canonical text lives in the doctrine files named in each row.

| Rule | What it means | Canonical |
|---|---|---|
| **Other-corpus reviews, strictly** | Every spec, plan, code and PR-comment review comes from a model that did not write the work: GLM/MiniMax/DeepSeek via `pi` or `crush`, GPT via `codex`, Grok via `grok`, plus `cline` and `octo`. Same-corpus Claude subagents review only as the last rung. Adversarial framing always; praise-only output is a null result. | `conejo-code/references/agent-dispatch.md` — list models: `pi-help` / `pi --list-models`, `crush models`, codex `/model` or `~/.codex/config.toml`, `grok models`, `cline auth`, `octo list`; select: `pi --provider X --model Y`, `crush run -m`, `codex exec -m`, `grok -m`, `cline -P … -m …`, `octo prompt --model` |
| **Acceptance criteria on every plan task** | No exceptions. Each criterion is an observable behavior plus an independent measurer runnable by someone who never read the diff. Measurers go RED before and GREEN after; the reviewer runs them; the ledger records their output. | `conejo-code/references/acceptance-criteria.md` |
| **Stacked PRs via `gh stack`** | GitHub supports stacks natively. One plan = one stack, one task = one layer (`feat/<plan>-<N>-<slug>`), `gh stack add` / `push` / `rebase --no-trunk` / `merge`; never hand-rebase the chain. Explain stacks to the partner once per project. | `conejo-code/references/stacked-prs-and-ci.md` |
| **Wait for CI/CD only on the last task** | Middle of a plan: commit, `gh stack push`, next task — no polling of Actions or bots. Last task: wait with a 10-minute cap, then process comments. Runners that never start (billing) are not a failure to wait on; local suite + measurers are the evidence. | `conejo-code/references/stacked-prs-and-ci.md` |
| **PR comments one by one** | Every comment gets its own verdict (`implement` / `push back` / `duplicate-of-#N`) and its own in-thread reply; `implemented + pushed-back + duplicate-linked == total`. The weird nit is the likely hidden gem. | `conejo-merge` Phase 5 |

### Stack preference (house tooling)

| Area | Use | Never |
|---|---|---|
| Package managers | `pnpm` (TS/JS), `uv` (Python), `cargo` (Rust) | npm, bun, yarn, pip, poetry |
| TS/JS | vite (build), vitest (tests), oxlint (lint), oxfmt (format), Astro (sites), elysia (servers), ESM only | jest, biome, eslint, prettier |
| Python | uv, pyrefly (types), ruff (lint/format), pytest, async-first stack | mypy/pyright unless already wired |
| Rust | cargo-nextest (`cargo nextest run`), clippy, rustfmt, `mbx` (mr_boxington: `mbx setup` once, then plain cargo runs through a shared, self-pruning build cache so builds don't explode context or disk) | — |
| Every project | complete README.md (what/install/usage/development) with CI/version/license/coverage badges, GitHub topics, tagged semver releases, packages published via **OIDC trusted publishing** (npm / PyPI / crates.io) | long-lived publish tokens |

### Vendored superpowers skills

15 skills come from [obra/superpowers](https://github.com/obra/superpowers) **v7.0.2** (`22f0b46`):
`brainstorming`, `diagnosing-superpowers`, `dispatching-parallel-agents`, `executing-plans`,
`finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`,
`subagent-driven-development`, `systematic-debugging`, `test-driven-development`,
`using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`,
`writing-skills`. Upstream text (SKILL.md, scripts, prompts, references) is kept verbatim; local
rules live only in the `<!-- conejo:start --> … <!-- conejo:end -->` block at the end of each
SKILL.md and are re-applied by `scripts/refresh-superpowers.sh`. In this bundle
`superpowers:<name>` references resolve as `<name>` (or `arthrod-skills:<name>`).

## Sync

```bash
./scripts/update-skills.sh                   # publish (default): refresh vendored from upstream,
                                             #   then ./skills/ → ~/.agents (copies) + ~/.claude and
                                             #   every other agent's skills dir (symlinks)
./scripts/update-skills.sh --skip-vendored   # publish, skip the upstream refresh step
./scripts/update-skills.sh --reverse         # subscribe: ~/.claude/skills → ./skills/ (additive)
./scripts/update-skills.sh --reverse --yolo  # subscribe, wipe ./skills/ first
DRY_RUN=1 ./scripts/update-skills.sh         # dry run, no writes anywhere

REF=v7.0.2 ./scripts/refresh-superpowers.sh  # re-vendor the superpowers skills (conejo blocks re-applied)
DRY_RUN=1 ./scripts/refresh-superpowers.sh   # show what a refresh would touch
```

## Install

```bash
/plugin marketplace add arthrod/conejo-skills
/plugin install arthrod-skills
```

## Family Map

| Family | Skills |
|---|---|
| **PR / code review workflow** | `conejo-merge`, `conejo-debug`, `conejo`, `code-review`, `receiving-code-review`, `requesting-code-review` |
| **Design (Stitch-first)** | `impeccable`, `adapt` — plus 13 design/UI skills folded under `conejo-frontend/refs/` (not separately invocable: `layout`, `ui-ux-pro-max`, `ux-design-brief`, `shadcn-parity`, `stitch-design-taste`, `refine-distill-frontend`, `increase-impact-personality-frontend`, `typeset`, `colorize`, `type-mania`, `tanstack-router`, `tanstack-router-best-practices`, `json-render`, `seo-audit`) |
| **Pydantic AI** | `pydantic-acp`, `pydantic-ai-agent-builder`, `pydanticai-docs`, `pydantic-ai-common-pitfalls`, `pydantic-ai-testing` |
| **Better Auth** | `better-auth`, `better-auth-best-practices`, `better-auth-security`, `better-auth-providers`, `better-auth-explain-error`, `better-auth-tauri-setup`, `better-auth-tauri-pitfalls` |
| **Rust** | `rust-author`, `rust-review` |
| **Pi terminal agent** | `pi-using`, `pi-extending` |
| **Testing / QA** | `testing-strategy`, `testing-review`, `browser-test-agent`, `desktop-test-agent-tauri`, `dogfood`, `dogfood-quirks` |
| **AI SDKs / Agents** | `llm-chat-sdks`, `ag-ui-copilotkit`, `ag-ui-pydantic`, `mcp-builder`, `agent-architecture-analysis`, `computer-use-agents`, `orchestrating-swarms`, `deepagents` |
| **ML / GPU** | `ml-gpu-training` |
| **i18n / Docs / Blog / Releases** | `i18n-inlang-localization`, `blog-handoff`, `blog-writing`, `adr`, `changeset` |
| **Process discipline (vendored from obra/superpowers v7.0.2 + `conejo` blocks)** | `diagnosing-superpowers`, `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `systematic-debugging`, `verification-before-completion`, `test-driven-development`, `using-superpowers`, `using-git-worktrees`, `writing-skills`, `finishing-a-development-branch` |
| **Frontend stacks** | `react`, `react-best-practices`, `react-composables`, `tailwind-v4`, `hono` |
| **Infra / env / sandbox / Val Town** | `env-dogma`, `val-town`, `agent-sandbox` |
| **Legal** | `conejo-legal` |
| **Other** | `advanced-elicitation`, `coderlm`, `draft-docs`, `major-task`, `marimo`, `python-code-review`, `ralph-prd-generator`, `review-llm-artifacts`, `review-plan`, `review-python`, `review-rust`, `sqlalchemy-code-review`, `sqlite-vec` |

## Full Index

### `adapt`

Adapt designs to work across different screen sizes, devices, contexts, or platforms. Implements breakpoints, fluid layouts, and touch targets. Use when the user mentions responsive design, mobile layouts, breakpoints,…

### `adr`

Architectural Decision Record (ADR) workflow — extract decisions from conversations/transcripts, then format them as MADR documents with Definition of Done (E.C.A.D.R.). Covers the full extract → write pipeline. Trigger…

### `advanced-elicitation`

Use when you want to improve response quality through meta-cognitive reasoning. Applies 15+ reasoning methods to reconsider and refine initial outputs.

### `ag-ui-copilotkit`

Build agentic UIs using AG-UI protocol with Pydantic AI (Python backend) and CopilotKit (React/Next.js frontend). Use when creating AI-powered applications that need bidirectional agent-UI communication, shared state be…

### `ag-ui-pydantic`

Build AI agent UIs using the AG-UI protocol with pydantic-ai (Python backend) and CopilotKit (React frontend). Use when creating agentic chat interfaces, human-in-the-loop workflows, generative UIs with state management…

### `agent-architecture-analysis`

Use when auditing an agent codebase against the 12-Factor Agents methodology, reviewing LLM-powered system architecture, or assessing agentic app compliance. Triggers on \"analyze agent architecture\", \"12-factor audit…

### `agent-sandbox`

Kernel-enforced (landlock) capability-based sandbox for running AI agents and untrusted code via nono — restrict filesystem, block network, inject credentials, take rollback snapshots, audit trails. Use for sandboxing a…

### `better-auth`

Skill for integrating Better Auth - comprehensive TypeScript authentication framework for Cloudflare D1, Next.js, Nuxt, and 15+ frameworks. Use when adding auth, encountering D1 adapter errors, or implementing OAuth/2FA…

### `better-auth-best-practices`

Best-practices guide for Better Auth's most-used features — email/password authentication (verification, password reset, hashing, policies), organization plugin (multi-tenant orgs, teams, RBAC), and two-factor authentic…

### `better-auth-explain-error`

Explain Better Auth error codes and provide solutions with code examples

### `better-auth-providers`

Display Better Auth available authentication providers and their configuration

### `better-auth-security`

This skill provides guidance for implementing security features that span across Better Auth, including rate limiting, CSRF protection, session security, trusted origins, secret management, OAuth security, IP tracking,…

### `better-auth-tauri-pitfalls`

Debugging guide and platform-specific gotchas for @daveyplate/better-auth-tauri. Use when troubleshooting auth failures in Tauri desktop apps, diagnosing 404 callback errors, fixing macOS cookie/deep-link issues, or deb…

### `better-auth-tauri-setup`

Integration guide for @daveyplate/better-auth-tauri - cookie-based auth in Tauri v2 desktop apps via deep links. Use when setting up Better Auth in a Tauri application, configuring social OAuth for desktop, or wiring up…

### `blog-handoff`

Use when a research/development session is ending and the work needs to be captured for a blog post writer. Triggers on "handoff", "blog post", "write up the work", "capture for blog", "document what we did". You MUST p…

### `blog-writing`

Use when writing a technical blog post from a BLOG_HANDOFF.md document. Triggers on "write the blog", "draft the post", "blog from handoff", "turn this into a blog". REQUIRES a handoff document as input — use blog-hando…

### `brainstorming`

You MUST use this before any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new, in software or out of it (a talk, a business, a renovation).

### `browser-test-agent`

Web browser automation & testing for AI agents — agent-browser CLI (Chrome/CDP, fill forms, click, scrape, screenshot, dev-server verification with page-load + console-error + UI-element checks) plus Playwright toolkit…

### `changeset`

Write concise package-release changesets for monorepo publishing — one action verb + one impact statement per bullet, imperative voice, user-impact only. Use when creating a `.changeset/*.md` for a published package.

### `code-review`

AI-powered code review using CodeRabbit. Default code-review skill. Trigger for any explicit review request AND autonomously when the agent thinks a review is needed (code/PR/quality/security).

### `coderlm`

Primary tool for all code navigation and reading in supported languages (Rust, Python, TypeScript, JavaScript, Go, Java, Scala, SQL). Use instead of Read, Grep, and Glob for finding symbols, reading function implementat…

### `computer-use-agents`

Build AI agents that interact with computers like humans do -

### `conejo`

arthrod's coding philosophy and dispatcher. Universal red-green TDD, acceptance criteria with independent measurers on every task, stacked PRs via `gh stack`, evidence-before-claims, context-preserving agent dispatch to…

### `conejo-code`

Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review→loop), red-green TDD execution, acceptance criteria with independent measurers on every task, context-preserving agent dispat…

### `conejo-debug`

Skeptical investigation and autonomous deep work — hunt PRs like crime scenes, interrogate code and CodeRabbit plans, systematic debugging with multi-agent second opinions from OTHER corpora (pi first via `pi-help` — fa…

### `conejo-frontend`

VERY STRICT frontend gate. Enforces the universal red-green doctrine PLUS the UI superset — agent-browser E2E click-flows (NEVER tRPC to assert UI), 24/7 dev server, test isolation, Astro Framework and Typescript or Rea…

### `conejo-legal`

Research a single US doctrinal legal issue with PR-review discipline and produce a source-audited OKF legal_issue bundle (SKOS digest, source/snippet audit, retained sources), with every run ending merged or closed. Use…

### `conejo-merge`

Main PR-comment handler — calm-implement mode (gate each comment individually, group into tasks, test/install/ship, reply with state changes). Hidden-gems doctrine — different review bots have different training corpora…

### `deepagents`

Deep Agents framework — architectural decisions (when to use Deep Agents vs alternatives, backend strategies, subagent design, middleware approaches) AND code review (bugs, anti-patterns, improvements when reviewing Dee…

### `desktop-test-agent-tauri`

Desktop & Tauri app testing for AI agents — Tauri v2 + WebKitGTK in Docker (AppImage extraction, Gemini Computer Use, virtual display, DOCX export verification) plus Electron app automation (VS Code, Slack, Discord, Fig…

### `diagnosing-superpowers`

Use when a superpowers session went wrong and your human partner wants to know why — repeated work, ignored plans, stumbles, poor results, a skill that didn't fire, "it took too long", "why is it so expensive", "what is…

### `dispatching-parallel-agents`

Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies

### `dogfood`

Systematically explore and test a web application to find bugs, UX issues, and other problems. Use when asked to "dogfood", "QA", "exploratory test", "find issues", "bug hunt", "test this app/site/platform", or review t…

### `dogfood-quirks`

Workarounds for agent-browser version 0.26.0 quirks on Linux (sandbox launch failure, broken --timeout, silent stale refs, find-role syntax). Read BEFORE invoking the /dogfood skill or running any agent-browser command.…

### `draft-docs`

Generate first-draft technical documentation from code analysis

### `env-dogma`

Scorched-earth env/secrets refactor for Vite + Cloudflare Workers + Tauri. Use when consolidating .env sprawl, hardening secrets handling, or auditing env access patterns.

### `executing-plans`

Use when executing an implementation plan in the current session as the implementer yourself — your human partner chose inline execution, or no subagent tool is available

### `finishing-a-development-branch`

Use when implementation is complete, all tests pass, and you need to decide how to integrate the work

### `hono`

Efficiently develop Hono applications using Hono CLI. Supports documentation search, API reference lookup, request testing, and bundle optimization.

### `i18n-inlang-localization`

Everything i18n/localization for apps — inlang projects (setup, plugins, validation), translating app messages (machine translation, missing translations, base locale), and the `/translate` slash-command workflow. Trigg…

### `impeccable`

Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. Covers websites, landing pag…

### `llm-chat-sdks`

Build LLM-powered chat apps with the right SDK — Anthropic SDK / Claude API (prompt caching, thinking, tool use, batch, files, citations, memory, model migrations) AND Vercel AI SDK (useChat, streamText, tool calls, UIM…

### `major-task`

Work heavyweight framework or library tasks with planning-first research, selective deep analysis, and rigorous handoff

### `marimo`

Everything marimo — writing notebooks (cells, script-mode detection, reactivity), preparing them for scheduled batch runs (Pydantic params, CLI args, WandB), generating anywidget components, and checking WASM/Pyodide co…

### `mcp-builder`

Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services,…

### `ml-gpu-training`

Everything GLiNER NER — training-strategy decisions (hyperparam sweeps, LoRA vs full FT, loss/OOM/NaN debugging, eval, WandB tracking) AND remote-GPU ops (launching/monitoring runs on AMD GPU droplets via DigitalOcean,…

### `orchestrating-swarms`

Master multi-agent orchestration using Claude Code's TeammateTool and Task system. Use when coordinating multiple agents, running parallel code reviews, creating pipeline workflows with dependencies, building self-organ…

### `pi-extending`

Building & extending Pi — authoring TypeScript extensions (ExtensionAPI, registerTool, registerProvider, /commands, UI hooks), publishing as npm/git packages (pi-package), embedding via JSON-RPC mode (--mode rpc/json, J…

### `pi-using`

Using the Pi terminal agent — workspace setup, sessions, /commands, compaction, settings.json/AGENTS.md, skill discovery, providers/models, plus theme/keybinding/prompt customization (SYSTEM.md, APPEND_SYSTEM.md, settin…

### `pydantic-acp`

Use pydantic-acp to drive an external ACP CLI agent (crush-acp, cline --acp) as a pydantic-ai model backend — create_acp_model, AcpProvider, delegate host clients (filesystem/terminal/permissions), PromptedOutput struct…

### `pydantic-ai-agent-builder`

Expert guidance for building AI agents with Pydantic AI framework. Use when creating multi-agent systems, AI orchestration workflows, or structured LLM applications with type safety and validation.

### `pydantic-ai-common-pitfalls`

Avoid common mistakes and debug issues in PydanticAI agents. Use when encountering errors, unexpected behavior, or when reviewing agent implementations.

### `pydantic-ai-testing`

Test PydanticAI agents using TestModel, FunctionModel, VCR cassettes, and inline snapshots. Use when writing unit tests, mocking LLM responses, or recording API interactions.

### `pydanticai-docs`

Use this skill whenever the user is working with the Pydantic AI framework — including building AI agents, defining structured outputs with Pydantic models, wiring up tools/function calling, configuring model providers…

### `python-code-review`

Reviews Python code AND pytest test code — type safety, async patterns, error handling, common mistakes, plus pytest setup correctness (test file location, conftest.py wiring, asyncio_mode), fixtures, parametrize, mocki…

### `ralph-prd-generator`

Generates Product Requirements Documents (PRDs) and specifications for Ralph for Claude Code autonomous development. Use when users want to create a PRD, write specifications, plan a new project for Ralph, convert ideas into Ralph-compatible format (PROMPT.md, @fix_plan.md, specs/), or prepare requirements for autonomous AI development loops.

### `react`

React patterns with destructured props, compiler optimization, Effects, and Tailwind v4 syntax. ALWAYS use when using React.

### `react-best-practices`

Use when reading or writing React components (.tsx, .jsx files with React imports).

### `react-composables`

React component architecture for creating composable, accessible components with data attributes. Use when creating/updating composable components, not for higher-level feature/page components.

### `receiving-code-review`

Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind…

### `requesting-code-review`

Use when completing tasks, implementing major features, or before merging to verify work meets requirements

### `review-llm-artifacts`

Detects common LLM coding agent artifacts by spawning 4 parallel subagents

### `review-plan`

Review implementation plans for parallelization, TDD, types, libraries, and security before execution

### `review-python`

Comprehensive Python/FastAPI backend code review with optional parallel agents

### `review-rust`

Comprehensive Rust code review with optional parallel agents

### `rust-author`

Authoring & setting up Rust projects — idiomatic Rust (ownership/borrowing/cloning patterns, Result error handling, clippy config, static vs dynamic dispatch, performance, doc tests) plus project scaffolding (Cargo.toml…

### `rust-review`

Comprehensive Rust code review across four lenses — source code (ownership, borrowing, lifetimes, errors, trait design, unsafe, common mistakes), tests (unit, integration, async testing, mocking, property-based), tokio…

### `sqlalchemy-code-review`

Reviews SQLAlchemy code for session management, relationships, N+1 queries, and migration patterns. Use when reviewing SQLAlchemy 2.0 code, checking session lifecycle, relationship() usage, or Alembic migrations.

### `sqlite-vec`

sqlite-vec extension for vector similarity search in SQLite. Use when storing embeddings, performing KNN queries, or building semantic search features. Triggers on sqlite-vec, vec0, MATCH, vec_distance, partition key, f…

### `subagent-driven-development`

Use when executing implementation plans with independent tasks in the current session

### `systematic-debugging`

Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes

### `tailwind-v4`

Tailwind CSS v4 with CSS-first configuration and design tokens. Use when setting up Tailwind v4, defining theme variables, using OKLCH colors, or configuring dark mode. Triggers on @theme, @tailwindcss/vite, oklch, CSS…

### `test-driven-development`

Use when implementing any feature or bugfix, before writing implementation code

### `testing-review`

Review whole-repo test quality, rerun coverage, score remaining worth-testing files, inspect slow-drift and stale test debt, and publish the next testing batch. Use every few weeks or before large breaking changes and r…

### `testing-strategy`

Enforces dependency isolation, coverage, and test quality standards for Python pytest suites. Use when writing tests, fixing test failures, increasing coverage, or reviewing test quality. Triggers on: write tests, fix t…

### `using-git-worktrees`

Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback

### `using-superpowers`

Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions

### `val-town`

Use when building, editing, or deploying code on Val Town - the serverless Deno platform. Triggers on val.town, vals, vt CLI, std/sqlite, std/openai, std/blob, esm.town imports, .http.tsx/.cron.tsx/.email.tsx file namin…

### `verification-before-completion`

Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions…

### `writing-plans`

Use when you have a spec or requirements for a multi-step task, before touching code

### `writing-skills`

Use when creating new skills, editing existing skills, or verifying skills work before deployment
