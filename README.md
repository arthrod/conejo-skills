# arthrod's Skill Registry

**85 skills** — last sync `2026-05-27`. **v3.0.0**

Major restructure: families collapsed (Pi → 2 skills, Pydantic AI → 1 with `references/`,
Rust → `rust-author` + `rust-review`, Better Auth slimmed, design dials folded into `impeccable`),
new combined skills (`conejo` absorbs code-review + autofix + pr-triage-gh, `marimo` absorbs 4
marimo skills, `ml-gpu-training` absorbs CUDA setup). All design tools include a Stitch-first
mandate (`STITCH-DESIGN.md` in each design-skill folder). 13 design/UI skills folded into
`conejo-frontend/refs/` as reference docs.

## Conejo coding-philosophy family

The four `conejo-*` skills form a tightly coupled PR workflow. They share a doctrine
(`references/testing-doctrine.md` inside `conejo-code`) and route to each other.

| Skill | Role |
|---|---|
| **`conejo`** | Universal dispatcher/philosophy — enforces red-green TDD, stacked PRs, and evidence-before-claims. Routes incoming PR comments to the three specialised siblings below. |
| **`conejo-code`** | Active coding loop. Holds the canonical testing doctrine at `references/testing-doctrine.md` (red-green-refactor, no green-without-red, no implementation without a failing test). |
| **`conejo-frontend`** | VERY STRICT UI gate. Mandates agent-browser E2E click-flows for every UI assertion; forbids tRPC calls to assert UI state (allowed only for auth/seeding). Requires a 24/7 dev server, React + Tailwind v4 + shadcn/ui; rejects Ant Design. 13 design/UI skills live under `skills/conejo-frontend/refs/` as reference docs reached via its index — they are **not** standalone registered skills. |
| **`conejo-merge`** | Two-mode PR handler: **skeptical mode** (hunt PRs, interrogate the code/plan, file CR-plan issues, TDD-implement) and **calm-implement mode** (gate each comment, group into tasks, test/install/ship). Also documents the stacked-PR merge method. |

> **Foundational top-level skills** — `react`, `react-best-practices`, `react-composables`,
> `layout`, and `tailwind-v4` remain registered as independent top-level skills because they are
> used well beyond frontend work and are referenced by non-frontend skill families.

### Helper scripts

| Script | Purpose |
|---|---|
| `scripts/install-conejo-hooks.sh` | Opt-in hook installer: idempotently merges two **Claude Code** hooks into a `settings.json` (default `~/.claude/settings.json`, override with `--settings`) — a `PreToolUse(Edit|Write)` cookbook-check and a `Stop` bug-fix-learning hook. Supports `--dry-run`. Does **not** touch git hooks. |
| `scripts/sync-to-claude.sh` | Mirrors the `conejo-*` skills to `~/.claude/skills` and prunes the 13 folded design skills that now live inside `conejo-frontend/refs/`. Symlink-aware, refuses to delete locally-modified directories, supports `--dry-run` and `--root <path>`. |

## Sync

```bash
./scripts/update-skills.sh            # additive — only adds NEW skills (default, safe)
./scripts/update-skills.sh --yolo     # substitute — wipes ./skills/ and re-copies everything
DRY_RUN=1 ./scripts/update-skills.sh  # local only, no commit/push
SOURCE=/path ./scripts/update-skills.sh
```

## Install

```bash
/plugin marketplace add arthrod/conejo-skills
/plugin install arthrod-skills
```

## Family Map

| Family | Skills |
|---|---|
| **PR / code review workflow** | `conejo`, `code-review`, `proud-zanahoria`, `zanahoria-plans`, `zanahoria-multi-assumptions`, `zanahoria-decisions`, `receiving-code-review`, `requesting-code-review` |
| **Design (Stitch-first)** | `impeccable`, `adapt`, `layout` — plus 13 design/UI skills folded under `conejo-frontend/refs/` (not separately invocable: `ui-ux-pro-max`, `ux-design-brief`, `shadcn-parity`, `stitch-design-taste`, `refine-distill-frontend`, `increase-impact-personality-frontend`, `typeset`, `colorize`, `type-mania`, `tanstack-router`, `tanstack-router-best-practices`, `json-render`, `seo-audit`) |
| **Pydantic AI** | `pydantic-ai-agent-builder`, `pydanticai-docs`, `pydantic-ai-common-pitfalls`, `pydantic-ai-testing` |
| **Better Auth** | `better-auth`, `better-auth-best-practices`, `better-auth-security`, `better-auth-providers`, `better-auth-explain-error`, `better-auth-tauri-setup`, `better-auth-tauri-pitfalls` |
| **Rust** | `rust-author`, `rust-review` |
| **Pi terminal agent** | `pi-using`, `pi-extending` |
| **Testing / QA** | `testing-strategy`, `testing-review`, `plate-testing-strategy`, `browser-test-agent`, `desktop-test-agent-tauri`, `dogfood`, `dogfood-quirks` |
| **AI SDKs / Agents** | `llm-chat-sdks`, `ag-ui-copilotkit`, `ag-ui-pydantic`, `mcp-builder`, `agent-architecture-analysis`, `computer-use-agents`, `orchestrating-swarms`, `deepagents` |
| **ML / GPU** | `ml-gpu-training` |
| **i18n / Docs / Blog / Releases** | `i18n-inlang-localization`, `blog-handoff`, `blog-writing`, `adr`, `changeset`, `pr-docx` |
| **Process discipline (local copies — also exist in superpowers plugin)** | `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `systematic-debugging`, `verification-before-completion`, `test-driven-development`, `using-superpowers`, `using-git-worktrees`, `writing-skills`, `finishing-a-development-branch` |
| **Frontend stacks** | `react`, `react-best-practices`, `react-composables`, `tailwind-v4`, `hono` |
| **Infra / env / sandbox / Val Town** | `env-dogma`, `val-town`, `agent-sandbox` |
| **Other** | `advanced-elicitation`, `coderlm`, `draft-docs`, `major-task`, `marimo`, `python-code-review`, `ralph-prd-generator`, `review-llm-artifacts`, `review-plan`, `review-python`, `review-rust`, `sqlalchemy-code-review`, `sqlite-vec`, `work-task` |

## Full Index

### `adapt`

Adapt designs to work across different screen sizes, devices, contexts, or platforms. Implements breakpoints, fluid layouts, and touch targets. Use when the user mentions responsive design, mobile layouts, breakpoints, v…

### `adr`

Architectural Decision Record (ADR) workflow — extract decisions from conversations/transcripts, then format them as MADR documents with Definition of Done (E.C.A.D.R.). Covers the full extract → write pipeline. Triggers…

### `advanced-elicitation`

Use when you want to improve response quality through meta-cognitive reasoning. Applies 15+ reasoning methods to reconsider and refine initial outputs.

### `ag-ui-copilotkit`

Build agentic UIs using AG-UI protocol with Pydantic AI (Python backend) and CopilotKit (React/Next.js frontend). Use when creating AI-powered applications that need bidirectional agent-UI communication, shared state bet…

### `ag-ui-pydantic`

Build AI agent UIs using the AG-UI protocol with pydantic-ai (Python backend) and CopilotKit (React frontend). Use when creating agentic chat interfaces, human-in-the-loop workflows, generative UIs with state management,…

### `agent-architecture-analysis`

Use when auditing an agent codebase against the 12-Factor Agents methodology, reviewing LLM-powered system architecture, or assessing agentic app compliance. Triggers on \"analyze agent architecture\", \"12-factor audit\…

### `agent-sandbox`

Kernel-enforced (landlock) capability-based sandbox for running AI agents and untrusted code via nono — restrict filesystem, block network, inject credentials, take rollback snapshots, audit trails. Use for sandboxing ag…

### `better-auth`

Skill for integrating Better Auth - comprehensive TypeScript authentication framework for Cloudflare D1, Next.js, Nuxt, and 15+ frameworks. Use when adding auth, encountering D1 adapter errors, or implementing OAuth/2FA/…

### `better-auth-best-practices`

Best-practices guide for Better Auth's most-used features — email/password authentication (verification, password reset, hashing, policies), organization plugin (multi-tenant orgs, teams, RBAC), and two-factor authentica…

### `better-auth-explain-error`

Explain Better Auth error codes and provide solutions with code examples

### `better-auth-providers`

Display Better Auth available authentication providers and their configuration

### `better-auth-security`

This skill provides guidance for implementing security features that span across Better Auth, including rate limiting, CSRF protection, session security, trusted origins, secret management, OAuth security, IP tracking, a…

### `better-auth-tauri-pitfalls`

Debugging guide and platform-specific gotchas for @daveyplate/better-auth-tauri. Use when troubleshooting auth failures in Tauri desktop apps, diagnosing 404 callback errors, fixing macOS cookie/deep-link issues, or debu…

### `better-auth-tauri-setup`

Integration guide for @daveyplate/better-auth-tauri - cookie-based auth in Tauri v2 desktop apps via deep links. Use when setting up Better Auth in a Tauri application, configuring social OAuth for desktop, or wiring up …

### `blog-handoff`

Use when a research/development session is ending and the work needs to be captured for a blog post writer. Triggers on "handoff", "blog post", "write up the work", "capture for blog", "document what we did". You MUST pa…

### `blog-writing`

Use when writing a technical blog post from a BLOG_HANDOFF.md document. Triggers on "write the blog", "draft the post", "blog from handoff", "turn this into a blog". REQUIRES a handoff document as input — use blog-handof…

### `brainstorming`

You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.

### `browser-test-agent`

Web browser automation & testing for AI agents — agent-browser CLI (Chrome/CDP, fill forms, click, scrape, screenshot, dev-server verification with page-load + console-error + UI-element checks) plus Playwright toolkit f…

### `changeset`

Write concise package-release changesets for monorepo publishing — one action verb + one impact statement per bullet, imperative voice, user-impact only. Use when creating a `.changeset/*.md` for a published package.

### `code-review`

AI-powered code review using CodeRabbit CLI (`coderabbit review --agent`). Default code-review skill. Trigger for any explicit review request AND autonomously when the agent thinks a review is needed (code/PR/quality/security).

### `coderlm`

Primary tool for all code navigation and reading in supported languages (Rust, Python, TypeScript, JavaScript, Go, Java, Scala, SQL). Use instead of Read, Grep, and Glob for finding symbols, reading function implementati…

### `computer-use-agents`

Build AI agents that interact with computers like humans do - viewing screens, moving cursors, clicking buttons, and typing text. Covers Anthropic's Computer Use, OpenAI's Operator/CUA, and open-source alternatives.

### `conejo`

Main PR-comment handler. Two modes — skeptical (hunt PRs, file CR-plan issues, TDD-implement) and calm-implement (gate each comment, group into tasks, test/install/ship). Use for conejo, rabbit review, just implement, sh…

### `deepagents`

Deep Agents framework — architectural decisions (when to use Deep Agents vs alternatives, backend strategies, subagent design, middleware approaches) AND code review (bugs, anti-patterns, improvements when reviewing Deep…

### `desktop-test-agent-tauri`

Desktop & Tauri app testing for AI agents — Tauri v2 + WebKitGTK in Docker (AppImage extraction, Gemini Computer Use, virtual display, DOCX export verification) plus Electron app automation (VS Code, Slack, Discord, Figm…

### `dispatching-parallel-agents`

Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies

### `dogfood`

Systematically explore and test a web application to find bugs, UX issues, and other problems. Use when asked to "dogfood", "QA", "exploratory test", "find issues", "bug hunt", "test this app/site/platform", or review th…

### `dogfood-quirks`

Workarounds for agent-browser version 0.26.0 quirks on Linux (sandbox launch failure, broken --timeout, silent stale refs, find-role syntax). Read BEFORE invoking the /dogfood skill or running any agent-browser command. …

### `draft-docs`

Generate first-draft technical documentation from code analysis

### `env-dogma`

Scorched-earth env/secrets refactor for Vite + Cloudflare Workers + Tauri. Use when consolidating .env sprawl, hardening secrets handling, or auditing env access patterns.

### `executing-plans`

Use when you have a written implementation plan to execute in a separate session with review checkpoints

### `finishing-a-development-branch`

Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup

### `hono`

Efficiently develop Hono applications using Hono CLI. Supports documentation search, API reference lookup, request testing, and bundle optimization.

### `i18n-inlang-localization`

Everything i18n/localization for apps — inlang projects (setup, plugins, validation), translating app messages (machine translation, missing translations, base locale), and the `/translate` slash-command workflow. Trigge…

### `impeccable`

Create distinctive, production-grade frontend interfaces with high design quality. Generates creative, polished code that avoids generic AI aesthetics. Use when the user asks to build web components, pages, artifacts, po…

### `layout`

Improve layout, spacing, and visual rhythm. Fixes monotonous grids, inconsistent spacing, and weak visual hierarchy. Use when the user mentions layout feeling off, spacing issues, visual hierarchy, crowded UI, alignment …

### `llm-chat-sdks`

Build LLM-powered chat apps with the right SDK — Anthropic SDK / Claude API (prompt caching, thinking, tool use, batch, files, citations, memory, model migrations) AND Vercel AI SDK (useChat, streamText, tool calls, UIMe…

### `major-task`

Work heavyweight framework or library tasks with planning-first research, selective deep analysis, and rigorous handoff

### `marimo`

Everything marimo — writing notebooks (cells, script-mode detection, reactivity), preparing them for scheduled batch runs (Pydantic params, CLI args, WandB), generating anywidget components, and checking WASM/Pyodide com…

### `mcp-builder`

Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services, …

### `ml-gpu-training`

Everything GLiNER NER — training-strategy decisions (hyperparam sweeps, LoRA vs full FT, loss/OOM/NaN debugging, eval, WandB tracking) AND remote-GPU ops (launching/monitoring runs on AMD GPU droplets via DigitalOcean, c…

### `orchestrating-swarms`

Master multi-agent orchestration using Claude Code's TeammateTool and Task system. Use when coordinating multiple agents, running parallel code reviews, creating pipeline workflows with dependencies, building self-organi…

### `pi-extending`

Building & extending Pi — authoring TypeScript extensions (ExtensionAPI, registerTool, registerProvider, /commands, UI hooks), publishing as npm/git packages (pi-package), embedding via JSON-RPC mode (--mode rpc/json, JS…

### `pi-using`

Using the Pi terminal agent — workspace setup, sessions, /commands, compaction, settings.json/AGENTS.md, skill discovery, providers/models, plus theme/keybinding/prompt customization (SYSTEM.md, APPEND_SYSTEM.md, setting…

### `plate-testing-strategy`

Testing strategy for Plate/Slate editor work — pure unit tests, plugin contract tests, golden serializer tests. Use when planning test layers, auditing a flaky suite, or deciding what to skip.

### `pr-docx`

Comprehensive DOCX import/export handling for Plate editor with tracked changes and comments. Use when implementing or debugging DOCX file operations, mammoth.js modifications, suggestion/comment import from Word, or exp…

### `proud-zanahoria`

Use when reviewing a PR with contrarian inversion to stress-test changes via @coderabbitai, making specific factual claims about dependency behavior that Conejo can later verify by reading library source code. Triggers o…

### `pydantic-ai-agent-builder`

Expert guidance for building AI agents with Pydantic AI framework. Use when creating multi-agent systems, AI orchestration workflows, or structured LLM applications with type safety and validation.

### `pydantic-ai-common-pitfalls`

Avoid common mistakes and debug issues in PydanticAI agents. Use when encountering errors, unexpected behavior, or when reviewing agent implementations.

### `pydantic-ai-testing`

Test PydanticAI agents using TestModel, FunctionModel, VCR cassettes, and inline snapshots. Use when writing unit tests, mocking LLM responses, or recording API interactions.

### `pydanticai-docs`

Use this skill whenever the user is working with the Pydantic AI framework — including building AI agents, defining structured outputs with Pydantic models, wiring up tools/function calling, configuring model providers (…

### `python-code-review`

Reviews Python code AND pytest test code — type safety, async patterns, error handling, common mistakes, plus pytest setup correctness (test file location, conftest.py wiring, asyncio_mode), fixtures, parametrize, mockin…

### `ralph-prd-generator`

Generates Product Requirements Documents (PRDs) and specifications for Ralph for Claude Code autonomous development. Use when users want to create a PRD, write specifications, plan a new project for Ralph, convert ideas …

### `react`

React patterns with destructured props, compiler optimization, Effects, and Tailwind v4 syntax. ALWAYS use when using React.

### `react-best-practices`

Use when reading or writing React components (.tsx, .jsx files with React imports).

### `react-composables`

React component architecture for creating composable, accessible components with data attributes. Use when creating/updating composable components, not for higher-level feature/page components.

### `receiving-code-review`

Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind …

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

Authoring & setting up Rust projects — idiomatic Rust (ownership/borrowing/cloning patterns, Result error handling, clippy config, static vs dynamic dispatch, performance, doc tests) plus project scaffolding (Cargo.toml,…

### `rust-review`

Comprehensive Rust code review across four lenses — source code (ownership, borrowing, lifetimes, errors, trait design, unsafe, common mistakes), tests (unit, integration, async testing, mocking, property-based), tokio a…

### `sqlalchemy-code-review`

Reviews SQLAlchemy code for session management, relationships, N+1 queries, and migration patterns. Use when reviewing SQLAlchemy 2.0 code, checking session lifecycle, relationship() usage, or Alembic migrations.

### `sqlite-vec`

sqlite-vec extension for vector similarity search in SQLite. Use when storing embeddings, performing KNN queries, or building semantic search features. Triggers on sqlite-vec, vec0, MATCH, vec_distance, partition key, fl…

### `subagent-driven-development`

Use when executing implementation plans with independent tasks in the current session

### `systematic-debugging`

Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes

### `tailwind-v4`

Tailwind CSS v4 with CSS-first configuration and design tokens. Use when setting up Tailwind v4, defining theme variables, using OKLCH colors, or configuring dark mode. Triggers on @theme, @tailwindcss/vite, oklch, CSS v…

### `test-driven-development`

Use when implementing any feature or bugfix, before writing implementation code

### `testing-review`

Review whole-repo test quality, rerun coverage, score remaining worth-testing files, inspect slow-drift and stale test debt, and publish the next testing batch. Use every few weeks or before large breaking changes and re…

### `testing-strategy`

Enforces dependency isolation, coverage, and test quality standards for Python pytest suites. Use when writing tests, fixing test failures, increasing coverage, or reviewing test quality. Triggers on: write tests, fix te…

### `using-git-worktrees`

Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification

### `using-superpowers`

Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions

### `val-town`

Use when building, editing, or deploying code on Val Town - the serverless Deno platform. Triggers on val.town, vals, vt CLI, std/sqlite, std/openai, std/blob, esm.town imports, .http.tsx/.cron.tsx/.email.tsx file naming…

### `verification-before-completion`

Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions a…

### `work-task`

Work a task end-to-end with lean context gathering, implementation, and verification

### `writing-plans`

Use when you have a spec or requirements for a multi-step task, before touching code

### `writing-skills`

Use when creating new skills, editing existing skills, or verifying skills work before deployment

### `zanahoria-decisions`

Use after zanahoria-multi-assumptions has filed N parallel issue variants AND @coderabbitai has responded to all of them — closes the family by extracting the load-bearing assumption, naming a winner, capturing the decis…

### `zanahoria-multi-assumptions`

Use when the user wants a plan validated by @coderabbitai but the right approach is uncertain — file 2-3 parallel issues with the SAME GOAL but deliberately shuffled assumptions/layers/triggers, so CR has comparative mat…

### `zanahoria-plans`

Use when the user has a plan or implementation approach and wants it stress-tested via @coderabbitai plan in a GitHub issue. Triggers on zanahoria-plans, contrarian plan, inverted plan, stress-test plan, plan issue zanah…

