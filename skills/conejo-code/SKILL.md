---
name: conejo-code
description: Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review→loop), red-green TDD execution, acceptance criteria with independent measurers on every task, context-preserving agent dispatch to other-corpus models (pi first — scoped models via `pi-help`, favor zai/glm-5.3 and minimax/MiniMax-M3 — then crush/codex/grok/cline/octo, subagents last), adversarial reviews, stacked PRs via `gh stack` with CI wait only on the last task, coding standards, bug-fix learning. Owns the canonical testing, agent-dispatch, acceptance-criteria and stacked-PR/CI doctrines. Use when writing or changing code (backend, logic, APIs, libraries, CLIs).
---

# Conejo-code — active coding

The hands-on coding loop. Philosophy lives in [[conejo]]; this skill is how you execute
it — relentless, disciplined, experiment-driven, detail-obsessed.

**Autonomy rule:** you MUST be fully autonomous. ALWAYS set a timer when waiting for
(1) the user, (2) Claude agents, (3) Claude or any other tool, (4) pi/opencode/crush/
forge agents, or (5) external bots — especially **@coderabbitai**. NEVER expect that
a response will wake you up. **Max wait is 10 minutes.** After 10m with no reply,
stop waiting: proceed on best efforts with what you have, keep going diligently and
calmly, and leave a short note that you proceeded without the reply. Never block the
plan forever on a silent agent. Implement the original plan, inferring the best
alternatives to make it work.

## Issues first — file on GitHub, then implement

Arthur, 2026-10-16: every issue goes on GitHub first, and only after that is it implemented.

- IF there is work to do (a feature, a bug, a defect a review confirms, a failing fixture, each item of a hand-written list) THEN file it as a GitHub issue BEFORE anyone, you or an agent, writes code for it. No issue, no implementation.
- End every issue with `@coderabbitai plan`.
- The default is NOT to wait for @coderabbitai: start implementing as soon as the issue exists. When its plan arrives, treat it as input and check each claim against the code. This overrides the 10-minute wait in the autonomy rule for CR plans.
- For discipline, always keep an account of the main issues being tackled: one tracking issue whose checklist names every sub-issue with its status, branch and PR. Update it as work lands, so the state of the work can always be read on GitHub.

## Step 0 — Resolve your dispatcher (ONCE, before the loop)

Read `references/agent-dispatch.md` (the Warren Protocol) — it is canonical. The short
version:

```bash
for c in pi crush codex grok cline octo; do command -v "$c" >/dev/null 2>&1 && echo "HAVE $c"; done
```

Keep every tool that answers — each is a different corpus. Default order: **pi → crush
→ codex → grok → cline → octo → subagents**.

- **List and pick models** (verified commands, headless shapes, per tool):
  `pi-help` / `pi --list-models [q]` · `crush models [q]` · codex: `/model` in the TUI
  or `model=` in `~/.codex/config.toml` · `grok models` · `cline auth` (TTY picker) ·
  `octo list`. Select with `pi --provider X --model Y`, `crush run -m provider/model`,
  `codex exec -m`, `grok -m`, `cline -P provider -m model`, `octo prompt --model
  "<nickname>"`. Full cheat-sheet: `references/agent-dispatch.md`.
- **Rule of the second corpus (strict):** the reviewer of any stage is never the model
  that produced it. You are Claude, so your reviewers are GLM/MiniMax/DeepSeek (pi,
  crush), GPT (codex) or Grok (grok). Same-corpus subagents review only as the last
  rung; they remain fine for implementers.
- NEVER decide "no agents available, I'll do everything inline." That torches your
  context AND forfeits the second pair of eyes.

**Why we dispatch (the two laws):** (1) context preservation — you orchestrate, they
excavate; only conclusions enter your context; (2) adversarial diversity — a different
training corpus catches what yours cannot, and a reviewer told to refute finds what an
admirer never will.

## The loop (feature stages, dispatch-annotated)

Full stage notes: `references/feature-stages.md`. UI stages (design/UIUX review) and
any visual work are owned by [[conejo-frontend]].

| # | Stage | Who | How |
|---|---|---|---|
| 1 | Brainstorm → written spec | You (+ user) | [[brainstorming]] |
| 2 | **Spec review — adversarial** | Other-corpus agent | `$DISPATCH`; model `zai/glm-5.3` (smartest, slow) |
| 3 | Plan | You | `references/feature-stages.md` Stage 1 |
| 4 | **Plan review — adversarial** | Other-corpus agent | `$DISPATCH`; model `zai/glm-5.3-highspeed` (a bit faster) |
| 5 | Interface (types/signatures, no impl) | You | — |
| 5.5 | **Acceptance criteria → measurers RED** | You | every task's criteria from the plan; run each independent measurer, record fail/absent (`references/acceptance-criteria.md`) |
| 6 | **Write failing tests (RED)** | Dispatched agent, in a CLONE | pi `zai/glm-5.3-highspeed` (deepseek stalls in `pi -p` — memory) — then YOU run them and verify they fail for the right reason |
| 7 | **Implement (GREEN)** | Dispatched agent, in a CLONE | pi `zai/glm-5.3-highspeed` or crush `zai/glm-5.3` — then YOU run the suite and verify green, then run the measurers and record GREEN |
| 8 | Improve tests | You or agent | `references/auto-improve-tests.md` |
| 9 | **Code review — adversarial** | Other-corpus agent (+ [[conejo-merge]] once PR'd) | reviewer prompt must REFUTE, never admire, and must RUN the measurers |
| 10 | Loop | — | commit, `gh stack add <branch>` / `gh stack push`, next task. **No CI/bot wait unless this was the last task** (`references/stacked-prs-and-ci.md`) |

Rules that ride along:

- IF a review stage (2, 4, 9) returns only praise THEN it's a null result — re-dispatch
  with a harsher prompt or a different model. Zero credit for praise.
- IF an agent finished THEN read its conclusion/diff, NOT its transcript. Transcripts
  stay in /tmp; conclusions enter your context.
- Don't be afraid of sending several agents: split the tasks as much as possible —
  up to 20 in parallel, one discrete unit each.
- NEVER let two agents write to the same directory — clone/worktree first.
- PR over PR ALWAYS, chained with `gh stack` — never hand-rebase the chain. Install
  once (`gh extension install github/gh-stack`), adopt existing branches with
  `gh stack init b1 b2 b3` (bottom to top; `gh stack add NEXT` for a new layer).
  `gh stack rebase --no-trunk` rebases every branch onto the one below it in one
  cascade; on conflict, resolve then `gh stack rebase --continue` (`--abort` restores
  every branch). `gh stack push` pushes all active branches, `gh stack submit`
  creates/updates the PRs. Push. After it is at GitHub, clean their mess.
- PRESERVE your context no matter what. Other-corpus agents first (different
  perspectives); if the work must be done anyway, send YOUR agents. Don't pollute
  your context.

### Canonical dispatch commands (full cheat-sheet: `references/agent-dispatch.md`)

```bash
# pi — default workhorse; scoped models via `pi-help`, all via `pi --list-models [q]`
( cd "$WORKDIR" && nohup pi --provider zai --model glm-5.3 --no-session \
    -p "$PROMPT" < /dev/null > /tmp/pi-$NAME.log 2>&1 & )
# crush — `crush models [q]` to list; -m model or provider/model; no -y (run rejects it)
nohup crush run -q -c "$WORKDIR" -m zai/glm-5.3 "$PROMPT" > /tmp/crush-$NAME.log 2>&1 &
# codex — OpenAI corpus; no list subcommand (/model in the TUI, model= in ~/.codex/config.toml)
( cd "$WORKDIR" && nohup codex exec -m gpt-6-astra -s workspace-write --approve-for-me \
    "$PROMPT" > /tmp/codex-$NAME.log 2>&1 & )
# grok — xAI corpus; `grok models` to list
( cd "$WORKDIR" && nohup grok -m grok-4.7 --permission-mode bypassPermissions --no-subagents \
    -p "$PROMPT" > /tmp/grok-$NAME.log 2>&1 & )
# cline — `cline auth` (TTY) to see/set provider+model; -y auto-approves; -p is PLAN mode
( cd "$WORKDIR" && nohup cline -y -c "$WORKDIR" -P <provider> -m <model> "$PROMPT" > /tmp/cline-$NAME.log 2>&1 & )
# octo — `octo list` for nicknames; single-shot, good for reviews/judgments
octo prompt --model "GLM 5.3 Flash (Synthetic)" "$PROMPT" > /tmp/octo-$NAME.log 2>&1
```

Flags drift: IF a flag is rejected THEN `<cli> <sub> --help`, re-map, retry once.

Then set the timer and poll — NOBODY wakes you up. Cap the wait at **10 minutes**:

```bash
# Poll every ~60s; stop at 10m wall-clock even if the agent is still silent
sleep 60; tail -20 /tmp/pi-$NAME.log   # repeat until done-marker OR 10 minutes elapsed
```

IF 10 minutes pass with no done-marker / no bot reply THEN proceed on best efforts
(what you have so far), keep going diligently and calmly, and note that you moved on
without the reply. Do not sleep forever.

Subagent fallback (no CLI found): one discrete unit per subagent; self-contained prompt
(paths, acceptance criteria, output format); launch all independent subagents in ONE
message; worktree isolation for writers; give each reviewer a different lens
(correctness / security / performance) — perspective diversity substitutes for corpus
diversity. Full recipe: `references/agent-dispatch.md`.

## Model preferences (when the CLI takes `--model`)

Run `pi-help` for the live scoped list; favor the best Chinese models available:

| IF | THEN model |
|---|---|
| Default — spec review | `zai/glm-5.3` (smartest but slow) |
| Default — plan review / failing tests / implement | `zai/glm-5.3-highspeed` |
| User wants a different POV, contrarian take, "what would X say", or distrusts a single model | `minimax/MiniMax-M3` (fast, 1M context) |
| User is "poor" (budget-constrained, signals `cheap`/`free`/`avoid paid`) | `zai/glm-5.3-flash` (or `nvidia/z-ai/glm-5.3-flash`) — always substitute the biggest available model of the family |
| DeepSeek corpus specifically | `nvidia/deepseek-ai/deepseek-v4.1-flash` (stalls in `pi -p` sometimes — fall back to glm/MiniMax) |
| A corpus that is neither Claude nor Chinese (tie-break, third opinion) | `gpt-6-astra` via codex, `grok-4.7` via grok |
| Last resort | any scoped method from `pi-help`; then subagents (same corpus — different lenses) |

IF swapping models for a stage THEN dispatch **2–4 agents in parallel** (one per family)
and judge: winner merges, runners-up get their best ideas grafted. Never sequentialize.

## Testing — READ FIRST

The universal red-green doctrine is canonical in `references/testing-doctrine.md`.
Backend/logic/CLI/library: `pnpm vitest run` (TS), `uv run pytest` (Python),
`cargo nextest run` (Rust); UI behavior uses agent-browser click-flows (see
[[conejo-frontend]]). Never implement before a failing test. RED must fail for the
RIGHT reason (assertion failure, not an import error).

**Acceptance criteria — READ SECOND.** Every task has them, each with an independent
measurer that goes RED before and GREEN after, run by you and by the reviewer:
`references/acceptance-criteria.md`. **Stacked PRs + CI:** `references/stacked-prs-and-ci.md`.

## Standards & helpers

- Coding standards: `references/coding-standards.md` (+ `-api-design.md`, `-testing.md`).
- Dependency hygiene (pnpm): `references/deps-check.md`.
- Capture bug-fix learnings: `references/bug-fix-learning.md`.
- Strengthen tests after green: `references/auto-improve-tests.md`.
- Optional auto-trigger hooks: `hooks/` — install with `scripts/install-conejo-hooks.sh`.

## Plan stress-testing (Zanahoria family)

Stress-test plans via @coderabbitai BEFORE you commit to implementation. Pick by
confidence:

- IF one plan and you want it battle-hardened → `references/zanahoria-plans` (inverted
  and re-asserted until CR produces a hardened version).
- IF torn between framings → `references/zanahoria-multi-assumptions` (2–3 parallel
  framings with deliberately shuffled assumptions, so CR gets comparative material).
- IF a multi-assumptions family needs closing → `references/zanahoria-decisions`
  (extract the load-bearing assumption, name a winner, capture an ADR, close the losers).

## Tooling (house stack — canonical list in `~/.claude/CLAUDE.md`)

pnpm (not npm, not bun, not yarn) · vite + vitest (not jest, not `bun test`) · oxlint +
oxfmt (not biome/eslint/prettier) · vite-plus (`vp`) where it is set up · ESM only ·
Python: uv + pyrefly (types) + ruff (lint/format) + pytest · Rust: cargo (through `mbx`, run `mbx setup` once) + cargo-nextest
+ clippy · sites: Astro · every project: complete README.md with badges, tagged semver
releases, packages published via OIDC trusted publishing.
