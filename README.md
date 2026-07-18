# arthrod's Skill Registry

**211 skills** — last sync `2026-07-17` (additive mode). **v2.0.0**

Major restructure: families collapsed (Pi → 2 skills, Pydantic AI → 1 with `references/`,
Rust → `rust-author` + `rust-review`, Better Auth slimmed, design dials folded into `impeccable`),
new combined skills (`conejo` absorbs code-review + autofix + pr-triage-gh, `marimo` absorbs 4
marimo skills, `ml-gpu-training` absorbs CUDA setup). All design tools include a Stitch-first
mandate (`STITCH-DESIGN.md` in each design-skill folder).

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
| **PR / code review workflow** | `conejo`, `proud-zanahoria`, `zanahoria-plans`, `zanahoria-multi-assumptions`, `zanahoria-decisions`, `receiving-code-review`, `requesting-code-review` |
| **Design (Stitch-first)** | `impeccable`, `adapt`, `layout` |
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
| **Other** | `advanced-elicitation`, `agent-browser`, `agents-sdk`, `ai-elements`, `app-intents-code-review`, `autofix`, `better-auth-security-best-practices`, `building-pydantic-ai-agents`, `cloudflare`, `cloudflare-email-service`, `code-review`, `code-review-standards`, `coderlm`, `coding-guidelines`, `conejo-code`, `conejo-debug`, `conejo-frontend`, `conejo-kitty`, `conejo-legal`, `conejo-merge`, `conejo-smith`, `core-actionbook`, `core-agent-browser`, `core-dynamic-skills`, `core-fix-skill-docs`, `create-auth`, `cross-review`, `deepagents-code-review`, `design-taste-frontend`, `docs-style`, `domain-cli`, `domain-cloud-native`, `domain-embedded`, `domain-fintech`, `domain-iot`, `domain-ml`, `domain-web`, `draft-docs`, `durable-objects`, `fetch-pr-feedback`, `ffi-code-review`, `find-skills`, `firecrawl`, `firecrawl-agent`, `firecrawl-build-interact`, `firecrawl-build-onboarding`, `firecrawl-build-scrape`, `firecrawl-build-search`, `firecrawl-company-directories`, `firecrawl-competitive-intel`, `firecrawl-crawl`, `firecrawl-dashboard-reporting`, `firecrawl-deep-research`, `firecrawl-demo-walkthrough`, `firecrawl-download`, `firecrawl-interact`, `firecrawl-knowledge-base`, `firecrawl-knowledge-ingest`, `firecrawl-lead-gen`, `firecrawl-lead-research`, `firecrawl-map`, `firecrawl-market-research`, `firecrawl-monitor`, `firecrawl-parse`, `firecrawl-qa`, `firecrawl-research-papers`, `firecrawl-scrape`, `firecrawl-search`, `firecrawl-seo-audit`, `firecrawl-shop`, `firecrawl-website-design-clone`, `firecrawl-workflows`, `frontend-patterns`, `humanize-beagle`, `init`, `m01-ownership`, `m02-resource`, `m03-mutability`, `m04-zero-cost`, `m05-type-driven`, `m06-error-handling`, `m07-concurrency`, `m09-domain`, `m10-performance`, `m11-ecosystem`, `m12-lifecycle`, `m13-domain-error`, `m14-mental-model`, `m15-anti-pattern`, `major-task`, `marimo`, `meta-cognition-parallel`, `organization-best-practices`, `pi-agent-rust`, `python-code-review`, `research`, `review-llm-artifacts`, `review-plan`, `review-python`, `review-rust`, `rust-best-practices`, `rust-call-graph`, `rust-code-navigator`, `rust-code-review`, `rust-daily`, `rust-deps-visualizer`, `rust-learner`, `rust-project-setup`, `rust-refactor-helper`, `rust-router`, `rust-skill-creator`, `rust-symbol-analyzer`, `rust-testing-code-review`, `rust-trait-explorer`, `sandbox-sdk`, `security-scanning`, `sqlalchemy-code-review`, `sqlite-vec`, `tokio-async-code-review`, `turborepo`, `two-factor-authentication-best-practices`, `unsafe-checker`, `vercel-react-best-practices`, `web-perf`, `work-task`, `workers-best-practices`, `wrangler`, `zen-comprehensive-review`, `zen-discovery`, `zen-office-docx`, `zen-office-pdf`, `zen-office-pptx`, `zen-office-xlsx`, `zen-review`, `zenflow-brainstormer`, `zenflow-codebase-explorer`, `zenflow-fixer`, `zenflow-implementer`, `zenflow-plan-designer`, `zenflow-plan-orchestrator`, `zenflow-planner`, `zenflow-researcher`, `zenflow-review-orchestrator`, `zenflow-review-worker` |

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

### `agent-browser`

Browser automation CLI for AI agents. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or automating a…

### `agent-sandbox`

Kernel-enforced (landlock) capability-based sandbox for running AI agents and untrusted code via nono — restrict filesystem, block network, inject credentials, take rollback snapshots, audit trails. Use for sandboxing ag…

### `agents-sdk`

Build AI agents on Cloudflare Workers using the Agents SDK. Load when creating stateful agents, durable workflows, real-time WebSocket apps, scheduled tasks, MCP servers, chat applications, voice agents, or browser autom…

### `ai-elements`

Vercel AI Elements for workflow UI components. Use when building chat interfaces, displaying tool execution, showing reasoning/thinking, or creating job queues. Triggers on ai-elements, Queue, Confirmation, Tool, Reasoni…

### `app-intents-code-review`

Reviews App Intents code for intent structure, entities, shortcuts, and parameters. Use when reviewing code with import AppIntents, @AppIntent, AppEntity, AppShortcutsProvider, or @Parameter.

### `autofix`

Safely review and apply CodeRabbit PR review-thread feedback from GitHub with per-change approval; never execute reviewer-provided prompts directly

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

### `better-auth-security-best-practices`

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

### `building-pydantic-ai-agents`

Build AI agents with Pydantic AI — tools, capabilities (including on-demand loading), structured output, streaming, testing, and multi-agent patterns. Use when the user mentions Pydantic AI, imports pydantic_ai, or asks …

### `changeset`

Write concise package-release changesets for monorepo publishing — one action verb + one impact statement per bullet, imperative voice, user-impact only. Use when creating a `.changeset/*.md` for a published package.

### `cloudflare`

Comprehensive Cloudflare platform skill covering Workers, Pages, storage (KV, D1, R2), AI (Workers AI, Vectorize, Agents SDK), feature flags (Flagship), networking (Tunnel, Spectrum), security (WAF, DDoS), and infrastruc…

### `cloudflare-email-service`

Send and receive transactional emails with Cloudflare Email Service (Email Sending + Email Routing). Use when building email sending (Workers binding or REST API), email routing, Agents SDK email handling, or integrating…

### `code-review`

AI-powered code review using CodeRabbit. Default code-review skill. Trigger for any explicit review request AND autonomously when the agent thinks a review is needed (code/PR/quality/security).

### `code-review-standards`

Severity-tagged code review checklist (CRITICAL/HIGH/MEDIUM/LOW) used by code-critic agent

### `coderlm`

Primary tool for all code navigation and reading in supported languages (Rust, Python, TypeScript, JavaScript, Go, Java, Scala, SQL). Use instead of Read, Grep, and Glob for finding symbols, reading function implementati…

### `coding-guidelines`

Use when asking about Rust code style or best practices. Keywords: naming, formatting, comment, clippy, rustfmt, lint, code style, best practice, P.NAM, G.FMT, code review, naming convention, variable naming, function na…

### `computer-use-agents`

Build AI agents that interact with computers like humans do - viewing screens, moving cursors, clicking buttons, and typing text. Covers Anthropic's Computer Use, OpenAI's Operator/CUA, and open-source alternatives.

### `conejo`

arthrod's coding philosophy and dispatcher. Universal red-green TDD, stacked PRs, evidence-before-claims, context-preserving agent dispatch (crush/opencode/subagents), hidden-gems review doctrine, no batch review. Routes…

### `conejo-code`

Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review→loop), red-green TDD execution, context-preserving agent dispatch via crush/opencode/other CLIs with subagent fallback, advers…

### `conejo-debug`

Skeptical investigation and autonomous deep work — hunt PRs like crime scenes, interrogate code and CodeRabbit plans, systematic debugging with multi-agent second opinions (crush/opencode/subagents), strict TDD fixes. Po…

### `conejo-frontend`

VERY STRICT frontend gate. Enforces the universal red-green doctrine PLUS the UI superset — agent-browser E2E click-flows (NEVER tRPC to assert UI), 24/7 dev server, test isolation, Astro Framework and Typescript or Reac…

### `conejo-kitty`

Policy for handling local-dev tooling files that hitchhiked into a PR (kitty-tmux-shim, claude-teams, dotfiles, IDE configs) and the merge strategy to use after PR review feedback is addressed. Invoke when bot reviewers …

### `conejo-legal`

Main PR-review-shaped legal research skill — legal issue bundle writer disguised as PR review operations. Hidden-gems doctrine for authorities: weird, pedantic, or out-of-corpus claims get MORE scrutiny, not less; batch …

### `conejo-merge`

Main PR-comment handler — calm-implement mode (gate each comment individually, group into tasks, test/install/ship, reply with state changes). Hidden-gems doctrine — different review bots have different training corpora,…

### `conejo-smith`

Project-local Smith installer. Recommended entry point. Downloads the latest hook scripts, settings fragment, and CLAUDE.md rubric from github.com/arthrod/smith at runtime, copies them into the current repo, then delegat…

### `core-actionbook`

Internal support skill for actionbook MCP selectors used by Rust documentation research workflows. Use only when another rust-skills workflow explicitly requests actionbook-backed selectors.

### `core-agent-browser`

Internal support skill for agent-browser CLI workflows used by rust-learner, docs-researcher, and crate-researcher. Use only when browser automation is explicitly required.

### `core-dynamic-skills`

Internal command support for dynamic Rust crate skill management. Use only when explicitly invoked by /sync-crate-skills, /clean-crate-skills, or /update-crate-skill.

### `core-fix-skill-docs`

Internal maintenance support for checking and fixing generated Rust skill documentation references. Use only when explicitly invoked by /fix-skill-docs.

### `create-auth`

Scaffold and implement authentication in TypeScript/JavaScript apps using Better Auth. Detect frameworks, configure database adapters, set up route handlers, add OAuth providers, and create auth UI pages. Use when users …

### `cross-review`

Cross review code using a subagent with a specified model. Use when the user asks to review code changes AND specifies a model to use (e.g., 'review with opus', 'use sonnet to review', 'review changes with gemini'). The …

### `deepagents`

Deep Agents framework — architectural decisions (when to use Deep Agents vs alternatives, backend strategies, subagent design, middleware approaches) AND code review (bugs, anti-patterns, improvements when reviewing Deep…

### `deepagents-code-review`

Reviews Deep Agents code for bugs, anti-patterns, and improvements. Use when reviewing code that uses create_deep_agent, backends, subagents, middleware, or human-in-the-loop patterns. Catches common configuration and us…

### `design-taste-frontend`

Anti-slop frontend skill for landing pages, portfolios, and redesigns. The agent reads the brief, infers the right design direction, and ships interfaces that do not look templated. Real design systems when applicable, a…

### `desktop-test-agent-tauri`

Desktop & Tauri app testing for AI agents — Tauri v2 + WebKitGTK in Docker (AppImage extraction, Gemini Computer Use, virtual display, DOCX export verification) plus Electron app automation (VS Code, Slack, Discord, Figm…

### `dispatching-parallel-agents`

Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies

### `docs-style`

Core technical documentation writing principles for voice, tone, structure, and LLM-friendly patterns. Use when writing or reviewing any documentation.

### `dogfood`

Systematically explore and test a web application to find bugs, UX issues, and other problems. Use when asked to "dogfood", "QA", "exploratory test", "find issues", "bug hunt", "test this app/site/platform", or review th…

### `dogfood-quirks`

Workarounds for agent-browser version 0.26.0 quirks on Linux (sandbox launch failure, broken --timeout, silent stale refs, find-role syntax). Read BEFORE invoking the /dogfood skill or running any agent-browser command. …

### `domain-cli`

Use when building CLI tools. Keywords: CLI, command line, terminal, clap, structopt, argument parsing, subcommand, interactive, TUI, ratatui, crossterm, indicatif, progress bar, colored output, shell completion, config f…

### `domain-cloud-native`

Use when building cloud-native apps. Keywords: kubernetes, k8s, docker, container, grpc, tonic, microservice, service mesh, observability, tracing, metrics, health check, cloud, deployment, 云原生, 微服务, 容器

### `domain-embedded`

Use when developing embedded/no_std Rust. Keywords: embedded, no_std, microcontroller, MCU, ARM, RISC-V, bare metal, firmware, HAL, PAC, RTIC, embassy, interrupt, DMA, peripheral, GPIO, SPI, I2C, UART, embedded-hal, cort…

### `domain-fintech`

Use when building fintech apps. Keywords: fintech, trading, decimal, currency, financial, money, transaction, ledger, payment, exchange rate, precision, rounding, accounting, 金融, 交易系统, 货币, 支付

### `domain-iot`

Use when building IoT apps. Keywords: IoT, Internet of Things, sensor, MQTT, device, edge computing, telemetry, actuator, smart home, gateway, protocol, 物联网, 传感器, 边缘计算, 智能家居

### `domain-ml`

Use when building ML/AI apps in Rust. Keywords: machine learning, ML, AI, tensor, model, inference, neural network, deep learning, training, prediction, ndarray, tch-rs, burn, candle, 机器学习, 人工智能, 模型推理

### `domain-web`

Use when building web services. Keywords: web server, HTTP, REST API, GraphQL, WebSocket, axum, actix, warp, rocket, tower, hyper, reqwest, middleware, router, handler, extractor, state management, authentication, author…

### `draft-docs`

Generate first-draft technical documentation from code analysis

### `durable-objects`

Create and review Cloudflare Durable Objects. Use when building stateful coordination (chat rooms, multiplayer games, booking systems), implementing RPC methods, SQLite storage, alarms, WebSockets, or reviewing DO code f…

### `env-dogma`

Scorched-earth env/secrets refactor for Vite + Cloudflare Workers + Tauri. Use when consolidating .env sprawl, hardening secrets handling, or auditing env access patterns.

### `executing-plans`

Use when you have a written implementation plan to execute in a separate session with review checkpoints

### `fetch-pr-feedback`

Fetch unresolved review comments from a PR and evaluate with receive-feedback skill

### `ffi-code-review`

Reviews Rust FFI code for type safety, memory layout compatibility, string handling, callback patterns, and unsafe boundary correctness. Use when reviewing extern blocks, #[repr(C)] types, bindgen output, or code calling…

### `find-skills`

Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. This skill should be used w…

### `finishing-a-development-branch`

Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup

### `firecrawl`

| Search, scrape, and interact with the web via the Firecrawl CLI. Use this skill whenever the user wants to search the web, find articles, research a topic, look something up online, scrape a webpage, grab content from …

### `firecrawl-agent`

| AI-powered autonomous data extraction that navigates complex sites and returns structured JSON. Use this skill when the user wants structured data from websites, needs to extract pricing tiers, product listings, direct…

### `firecrawl-build-interact`

Integrate Firecrawl `/interact` into product code for dynamic pages and browser actions after scraping. Use when a feature needs clicks, form fills, pagination, authentication-aware flows, or other multi-step interaction…

### `firecrawl-build-onboarding`

Get Firecrawl credentials and SDK setup into a project. Use when an application needs `FIRECRAWL_API_KEY`, when an agent should add Firecrawl to `.env`, when the user wants to authenticate Firecrawl for app code, or when…

### `firecrawl-build-scrape`

Integrate Firecrawl `/scrape` into product code for single-page extraction. Use when an app already has a URL and needs markdown, HTML, links, screenshots, metadata, or structured page output. Prefer this skill over broa…

### `firecrawl-build-search`

Integrate Firecrawl `/search` into product code and agent workflows. Use when an app needs discovery before extraction, when the feature starts with a query instead of a URL, or when the system should search the web and …

### `firecrawl-company-directories`

Extract structured company lists from directories with Firecrawl. Use for scraping YC, Crunchbase, Product Hunt, G2, startup directories, category directories, or custom company databases into JSON, CSV, CRM-ready lists,…

### `firecrawl-competitive-intel`

Monitor competitor pricing, features, changelogs, dashboards, and product changes with Firecrawl. Use for recurring competitive intelligence, pricing tier extraction, feature change tracking, or structured competitor ale…

### `firecrawl-crawl`

| Bulk extract content from an entire website or site section. Use this skill when the user wants to crawl a site, extract all pages from a docs section, bulk-scrape multiple pages following links, or says "crawl", "get …

### `firecrawl-dashboard-reporting`

Pull metrics from analytics dashboards and internal web tools with Firecrawl browser. Use when the user needs dashboard reporting, cross-platform metric summaries, authenticated analytics extraction, date-range reports, …

### `firecrawl-deep-research`

| Produce an intensive, cited analytical report: executive summary, multi-angle findings, contrarian views, open questions, and full sources. Use only when the user needs rigorous synthesis of a complex topic (scientific…

### `firecrawl-demo-walkthrough`

Walk through a product's key flows with Firecrawl browser and produce a structured UX/product walkthrough. Use for signup, onboarding, pricing, docs, dashboard, product demo prep, UX teardown, and first-run experience an…

### `firecrawl-download`

| Download an entire website as local files — markdown, screenshots, or multiple formats per page. Use this skill when the user wants to save a site locally, download documentation for offline use, bulk-save pages as fil…

### `firecrawl-interact`

| Control and interact with a live browser session on any scraped page — click buttons, fill forms, navigate flows, and extract data using natural language prompts or code. Use when the user needs to interact with a webp…

### `firecrawl-knowledge-base`

Build a knowledge base from web content with Firecrawl. Use for local reference docs, RAG-ready chunks, fine-tuning datasets, documentation mirrors, topic corpora, or LLM-ready markdown organized from web sources.

### `firecrawl-knowledge-ingest`

Ingest public or authenticated knowledge bases and docs portals with Firecrawl browser. Use for JS-heavy docs, login-gated portals, paginated help centers, support knowledge bases, or structured JSON/markdown extraction …

### `firecrawl-lead-gen`

Generate structured lead lists from prospect databases and web directories with Firecrawl browser. Use for finding prospects by role, company type, industry, stage, location, technologies, or other criteria and exporting…

### `firecrawl-lead-research`

Produce pre-meeting lead intelligence briefs with Firecrawl. Use when the user needs company research, person research, recent news, talking points, pain points, or outreach preparation before a sales call, partnership m…

### `firecrawl-map`

| Discover and list all URLs on a website, with optional search filtering. Use this skill when the user wants to find a specific page on a large site, list all URLs, see the site structure, find where something is on a d…

### `firecrawl-market-research`

Extract market, financial, earnings, industry, and company metrics with Firecrawl. Use when the user asks for market research, industry trends, public company data, financial comparisons, earnings research, or structured…

### `firecrawl-monitor`

| Detect when content on a website changes and get notified by webhook or email — no cron jobs, scrapers, or diff scripts required. Use this skill whenever the user wants to track changes on a page, watch competitor pric…

### `firecrawl-parse`

| Efficiently extract and convert the contents of any local file—such as PDF, DOCX, DOC, ODT, RTF, XLSX, XLS, or HTML—into clean, well-formatted markdown saved to disk. Use this skill whenever the user requests to parse,…

### `firecrawl-qa`

QA test a live website with Firecrawl browser and scrape evidence. Use when the user wants exploratory QA, form testing, navigation/link checks, responsive checks, performance observations, bug reports, or a pre-launch q…

### `firecrawl-research-papers`

Find and synthesize research papers, whitepapers, PDFs, technical reports, and academic sources with Firecrawl Research, using semantic paper search, related-paper expansion, and in-body verification. Use when the user w…

### `firecrawl-scrape`

| Extract clean markdown from any URL, including JavaScript-rendered SPAs. Use this skill whenever the user provides a URL and wants its content, says "scrape", "grab", "fetch", "pull", "get the page", "extract from this…

### `firecrawl-search`

| Web search with full page content extraction. Use this skill whenever the user asks to search the web, find articles, research a topic, look something up, find recent news, discover sources, or says "search for", "find…

### `firecrawl-seo-audit`

Audit a website's SEO with Firecrawl. Use when the user asks for an SEO audit, metadata and heading review, sitemap/site-structure analysis, keyword opportunities, competitor SERP comparison, or prioritized search optimi…

### `firecrawl-shop`

Research products across the web with Firecrawl and produce a shopping recommendation or cart-ready summary. Use when the user wants to compare products, find the best option, evaluate reviews, respect budget/preferences…

### `firecrawl-website-design-clone`

Extract any website's design system into an agent-ready DESIGN.md using Firecrawl scrape evidence. Use when the user wants colors, fonts, spacing, components, layout patterns, or brand/UI guidance from a website so AI ag…

### `firecrawl-workflows`

Run outcome-focused Firecrawl workflows that produce deliverables such as research reports, SEO audits, QA reports, lead lists, knowledge bases, website design systems, and other structured web-data artifacts. Use when t…

### `frontend-patterns`

Frontend development patterns for React, Next.js, state management, performance optimization, and UI best practices.

### `hono`

Efficiently develop Hono applications using Hono CLI. Supports documentation search, API reference lookup, request testing, and bundle optimization.

### `humanize-beagle`

Rewrite AI-generated developer text to sound human — fix inflated language, filler, tautological docs, and robotic tone. Use after review-ai-writing identifies issues.

### `i18n-inlang-localization`

Everything i18n/localization for apps — inlang projects (setup, plugins, validation), translating app messages (machine translation, missing translations, base locale), and the `/translate` slash-command workflow. Trigge…

### `impeccable`

Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. Covers websites, landing page…

### `init`

Use when the user asks to initialize a repo, create AGENTS.md, generate contributor guidelines, or set up agent-oriented documentation for a codebase.

### `layout`

Improve layout, spacing, and visual rhythm. Fixes monotonous grids, inconsistent spacing, and weak visual hierarchy. Use when the user mentions layout feeling off, spacing issues, visual hierarchy, crowded UI, alignment …

### `llm-chat-sdks`

Build LLM-powered chat apps with the right SDK — Anthropic SDK / Claude API (prompt caching, thinking, tool use, batch, files, citations, memory, model migrations) AND Vercel AI SDK (useChat, streamText, tool calls, UIMe…

### `m01-ownership`

CRITICAL: Use for ownership/borrow/lifetime issues. Triggers: E0382, E0597, E0506, E0507, E0515, E0716, E0106, value moved, borrowed value does not live long enough, cannot move out of, use of moved value, ownership, bor…

### `m02-resource`

CRITICAL: Use for smart pointers and resource management. Triggers: Box, Rc, Arc, Weak, RefCell, Cell, smart pointer, heap allocation, reference counting, RAII, Drop, should I use Box or Rc, when to use Arc vs Rc, 智能指针, …

### `m03-mutability`

CRITICAL: Use for mutability issues. Triggers: E0596, E0499, E0502, cannot borrow as mutable, already borrowed as immutable, mut, &mut, interior mutability, Cell, RefCell, Mutex, RwLock, 可变性, 内部可变性, 借用冲突

### `m04-zero-cost`

CRITICAL: Use for generics, traits, zero-cost abstraction. Triggers: E0277, E0308, E0599, generic, trait, impl, dyn, where, monomorphization, static dispatch, dynamic dispatch, impl Trait, trait bound not satisfied, 泛型, …

### `m05-type-driven`

CRITICAL: Use for type-driven design. Triggers: type state, PhantomData, newtype, marker trait, builder pattern, make invalid states unrepresentable, compile-time validation, sealed trait, ZST, 类型状态, 新类型模式, 类型驱动设计

### `m06-error-handling`

CRITICAL: Use for error handling. Triggers: Result, Option, Error, ?, unwrap, expect, panic, anyhow, thiserror, when to panic vs return Result, custom error, error propagation, 错误处理, Result 用法, 什么时候用 panic

### `m07-concurrency`

CRITICAL: Use for concurrency/async. Triggers: E0277 Send Sync, cannot be sent between threads, thread, spawn, channel, mpsc, Mutex, RwLock, Atomic, async, await, Future, tokio, deadlock, race condition, 并发, 线程, 异步, 死锁

### `m09-domain`

CRITICAL: Use for domain modeling. Triggers: domain model, DDD, domain-driven design, entity, value object, aggregate, repository pattern, business rules, validation, invariant, 领域模型, 领域驱动设计, 业务规则

### `m10-performance`

CRITICAL: Use for performance optimization. Triggers: performance, optimization, benchmark, profiling, flamegraph, criterion, slow, fast, allocation, cache, SIMD, make it faster, 性能优化, 基准测试

### `m11-ecosystem`

Use when integrating crates or ecosystem questions. Keywords: E0425, E0433, E0603, crate, cargo, dependency, feature flag, workspace, which crate to use, using external C libraries, creating Python extensions, PyO3, wasm…

### `m12-lifecycle`

Use when designing resource lifecycles. Keywords: RAII, Drop, resource lifecycle, connection pool, lazy initialization, connection pool design, resource cleanup patterns, cleanup, scope, OnceCell, Lazy, once_cell, OnceLo…

### `m13-domain-error`

Use when designing domain error handling. Keywords: domain error, error categorization, recovery strategy, retry, fallback, domain error hierarchy, user-facing vs internal errors, error code design, circuit breaker, grac…

### `m14-mental-model`

Use when learning Rust concepts. Keywords: mental model, how to think about ownership, understanding borrow checker, visualizing memory layout, analogy, misconception, explaining ownership, why does Rust, help me underst…

### `m15-anti-pattern`

Use when reviewing code for anti-patterns. Keywords: anti-pattern, common mistake, pitfall, code smell, bad practice, code review, is this an anti-pattern, better way to do this, common mistake to avoid, why is this bad,…

### `major-task`

Work heavyweight framework or library tasks with planning-first research, selective deep analysis, and rigorous handoff

### `marimo`

Everything marimo — writing notebooks (cells, script-mode detection, reactivity), preparing them for scheduled batch runs (Pydantic params, CLI args, WandB), generating anywidget components, and checking WASM/Pyodide com…

### `mcp-builder`

Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services, …

### `meta-cognition-parallel`

EXPERIMENTAL: Three-layer parallel meta-cognition analysis. Triggers on: /meta-parallel, 三层分析, parallel analysis, 并行元认知

### `ml-gpu-training`

Everything GLiNER NER — training-strategy decisions (hyperparam sweeps, LoRA vs full FT, loss/OOM/NaN debugging, eval, WandB tracking) AND remote-GPU ops (launching/monitoring runs on AMD GPU droplets via DigitalOcean, c…

### `orchestrating-swarms`

Master multi-agent orchestration using Claude Code's TeammateTool and Task system. Use when coordinating multiple agents, running parallel code reviews, creating pipeline workflows with dependencies, building self-organi…

### `organization-best-practices`

Configure multi-tenant organizations, manage members and invitations, define custom roles and permissions, set up teams, and implement RBAC using Better Auth's organization plugin. Use when users need org setup, team man…

### `pi-agent-rust`

>- Speeds up pi_agent_rust development and verification workflows. Use when editing providers, tools, sessions, extensions, installer/uninstaller logic, or triaging regressions in this repo.

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

### `research`

Fast agent specialized for exploring codebases and searching for code patterns. Use via spawn_subagent with skill='research' for read-only exploration tasks.

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

### `rust-best-practices`

> Development guidance for writing idiomatic Rust. Use when: (1) writing new Rust functions or modules, (2) choosing between borrowing, cloning, or ownership patterns, (3) implementing error handling with Result types, (…

### `rust-call-graph`

Visualize Rust function call graphs using LSP. Triggers on: /call-graph, call hierarchy, who calls, what calls, 调用图, 调用关系, 谁调用了, 调用了谁

### `rust-code-navigator`

Navigate Rust code using LSP. Triggers on: /navigate, go to definition, find references, where is defined, 跳转定义, 查找引用, 定义在哪, 谁用了这个

### `rust-code-review`

Reviews Rust code for ownership, borrowing, lifetime, error handling, trait design, unsafe usage, and common mistakes. Use when reviewing .rs files, checking borrow checker issues, error handling patterns, or trait imple…

### `rust-daily`

| CRITICAL: Use for Rust news and daily/weekly/monthly reports. Triggers on: rust news, rust daily, rust weekly, TWIR, rust blog, Rust 日报, Rust 周报, Rust 新闻, Rust 动态

### `rust-deps-visualizer`

Visualize Rust project dependencies as ASCII art. Triggers on: /deps-viz, dependency graph, show dependencies, visualize deps, 依赖图, 依赖可视化, 显示依赖

### `rust-learner`

Use when asking about Rust versions or crate info. Keywords: latest version, what's new, changelog, Rust 1.x, Rust release, stable, nightly, crate info, crates.io, lib.rs, docs.rs, API documentation, crate features, depe…

### `rust-project-setup`

> Guidance for scaffolding new Rust projects. Use when: (1) starting a new Rust project or workspace, (2) configuring Cargo.toml best practices, (3) setting up CI pipelines for Rust, (4) organizing a multi-crate workspac…

### `rust-refactor-helper`

Safe Rust refactoring with LSP analysis. Triggers on: /refactor, rename symbol, move function, extract, 重构, 重命名, 提取函数, 安全重构

### `rust-review`

Comprehensive Rust code review across four lenses — source code (ownership, borrowing, lifetimes, errors, trait design, unsafe, common mistakes), tests (unit, integration, async testing, mocking, property-based), tokio a…

### `rust-router`

|- CRITICAL: Use for ALL Rust questions including errors, design, and coding. HIGHEST PRIORITY for: 比较, 对比, compare, vs, versus, 区别, difference, 最佳实践, best practice, tokio vs, async-std vs, 比较 tokio, 比较 async, Triggers o…

### `rust-skill-creator`

Use when creating skills for Rust crates or std library documentation. Keywords: create rust skill, create crate skill, create std skill, 创建 rust skill, 创建 crate skill, 创建 std skill, 动态 rust skill, 动态 crate skill, skill …

### `rust-symbol-analyzer`

Analyze Rust project structure using LSP symbols. Triggers on: /symbols, project structure, list structs, list traits, list functions, 符号分析, 项目结构, 列出所有, 有哪些struct

### `rust-testing-code-review`

Reviews Rust test code for unit test patterns, integration test structure, async testing, mocking approaches, and property-based testing. Covers Rust 2024 edition changes including async fn in traits for mocks, #[expect]…

### `rust-trait-explorer`

Explore Rust trait implementations using LSP. Triggers on: /trait-impl, find implementations, who implements, trait 实现, 谁实现了, 实现了哪些trait

### `sandbox-sdk`

Build sandboxed applications for secure code execution. Load when building AI code execution, code interpreters, CI/CD systems, interactive dev environments, or executing untrusted code. Covers Sandbox SDK lifecycle, com…

### `security-scanning`

CI security scanning: secrets, deps, SAST, triage, expiring exceptions

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

### `tokio-async-code-review`

Reviews tokio async runtime usage for task management, sync primitives, channel patterns, and runtime configuration. Covers Rust 2024 edition changes including async fn in traits, RPIT lifetime capture, LazyLock, and if-…

### `turborepo`

| Turborepo monorepo build system guidance. Triggers on: turbo.json, task pipelines, dependsOn, caching, remote cache, the "turbo" CLI, --filter, --affected, CI optimization, environment variables, internal packages, mon…

### `two-factor-authentication-best-practices`

Configure TOTP authenticator apps, send OTP codes via email/SMS, manage backup codes, handle trusted devices, and implement 2FA sign-in flows using Better Auth's twoFactor plugin. Use when users need MFA, multi-factor au…

### `unsafe-checker`

CRITICAL: Use for unsafe Rust code review and FFI. Triggers on: unsafe, raw pointer, FFI, extern, transmute, *mut, *const, union, #[repr(C)], libc, std::ffi, MaybeUninit, NonNull, SAFETY comment, soundness, undefined beh…

### `using-git-worktrees`

Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification

### `using-superpowers`

Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions

### `val-town`

Use when building, editing, or deploying code on Val Town - the serverless Deno platform. Triggers on val.town, vals, vt CLI, std/sqlite, std/openai, std/blob, esm.town imports, .http.tsx/.cron.tsx/.email.tsx file naming…

### `vercel-react-best-practices`

React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on task…

### `verification-before-completion`

Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions a…

### `web-perf`

Analyzes web performance using Chrome DevTools MCP. Measures Core Web Vitals (LCP, INP, CLS) and supplementary metrics (FCP, TBT, Speed Index), identifies render-blocking resources, network dependency chains, layout shif…

### `work-task`

Work a task end-to-end with lean context gathering, implementation, and verification

### `workers-best-practices`

Reviews and authors Cloudflare Workers code against production best practices. Load when writing new Workers, reviewing Worker code, configuring wrangler.jsonc, or checking for common Workers anti-patterns (streaming, fl…

### `wrangler`

Cloudflare Workers CLI for deploying, developing, and managing Workers, KV, R2, D1, Vectorize, Hyperdrive, Workers AI, Containers, Queues, Workflows, Pipelines, and Secrets Store. Load before running wrangler commands to…

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

### `zen-comprehensive-review`

Orchestrate a multi-model code review: spawn 3 review subagents, merge findings. In PR mode, posts GitHub PR comments. In local mode, outputs findings directly. CRITICAL: this skill is costly, don't use it unless user ex…

### `zen-discovery`

Discover available integrations and their connection status. Use when the user asks what integrations are available, wants to check connection status across providers, or needs to connect a provider but no provider-speci…

### `zen-office-docx`

Create, read and edit professional Word documents (.docx) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, read, edit, modify, or write a Word document, .docx file, report, pr…

### `zen-office-pdf`

Create and read PDF documents (.pdf) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, or write a PDF document, or mentions .pdf, PDF, portable document, or needs a fixed-layou…

### `zen-office-pptx`

Create, read and edit professional PowerPoint presentations (.pptx) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, read, edit, modify, or write a presentation, slide deck, p…

### `zen-office-xlsx`

Create, read and edit professional Excel spreadsheets (.xlsx) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, read, edit, modify, or write a spreadsheet, workbook, data table…

### `zen-review`

Expert code reviewer. Analyze PR changes for correctness, security, performance, and quality. Returns findings as JSON. CRITICAL: this skill is costly, don't use it unless user explicitly requested to use it.

### `zenflow-brainstormer`

Single-shot ideation and research agent for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-codebase-explorer`

Read-only codebase explorer for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-fixer`

Single-pass fixer for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-implementer`

Single-pass implementer for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-plan-designer`

Draft implementation plan designer for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-plan-orchestrator`

Multi-model implementation plan orchestrator for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-planner`

Implementation planner for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-researcher`

Web research agent for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-review-orchestrator`

Multi-model code review orchestrator for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

### `zenflow-review-worker`

Static-analysis code review worker for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.

