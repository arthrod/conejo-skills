---
name: conejo-code
description: Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review→loop), red-green TDD execution, context-preserving agent dispatch via crush/opencode/other CLIs with subagent fallback, adversarial reviews, coding standards, bug-fix learning. Owns the canonical testing doctrine and the agent-dispatch doctrine. Use when writing or changing code (backend, logic, APIs, libraries, CLIs).
---

# Conejo-code — active coding

The hands-on coding loop. Philosophy lives in [[conejo]]; this skill is how you execute
it — relentless, disciplined, experiment-driven, detail-obsessed.

**Autonomy rule:** you MUST be fully autonomous. ALWAYS set a timer when waiting for
(1) the user, (2) Claude agents, (3) Claude or any other tool, (4) opencode/crush/
forge agents, or (5) external bots — especially **@coderabbitai**. NEVER expect that
a response will wake you up. **Max wait is 10 minutes.** After 10m with no reply,
stop waiting: proceed on best efforts with what you have, keep going diligently and
calmly, and leave a short note that you proceeded without the reply. Never block the
plan forever on a silent agent. Implement the original plan, inferring the best
alternatives to make it work.

## Step 0 — Resolve your dispatcher (ONCE, before the loop)

Read `references/agent-dispatch.md` (the Warren Protocol) — it is canonical. The short
version:

```bash
if   command -v crush    >/dev/null 2>&1; then DISPATCH=crush
elif command -v opencode >/dev/null 2>&1; then DISPATCH=opencode
elif command -v codex    >/dev/null 2>&1; then DISPATCH=codex
elif command -v gemini   >/dev/null 2>&1; then DISPATCH=gemini
elif command -v pi       >/dev/null 2>&1; then DISPATCH=pi
else DISPATCH=subagents; fi
```

- IF `crush` or `opencode` is available → dispatch stage work through it (templates below).
- ELIF another agent CLI is available → `<cli> --help | head -40`, find its headless
  mode (`run` / `exec` / `-p`), use it.
- ELSE → spawn subagents with your harness's Agent tool. Subagents ARE the Claude
  fallback — do the same splitting, the same parallel dispatch, the same adversarial
  prompts. A second `claude -p` adds nothing over them.
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
| 2 | **Spec review — adversarial** | Other-corpus agent | `$DISPATCH`; model `zai-coding-plan/glm-5.1` (smartest, slow) |
| 3 | Plan | You | `references/feature-stages.md` Stage 1 |
| 4 | **Plan review — adversarial** | Other-corpus agent | `$DISPATCH`; model `deepseek/deepseek-v4-pro` (a bit faster) |
| 5 | Interface (types/signatures, no impl) | You | — |
| 6 | **Write failing tests (RED)** | Dispatched agent, in a CLONE | `$DISPATCH`, deepseek — then YOU run them and verify they fail for the right reason |
| 7 | **Implement (GREEN)** | Dispatched agent, in a CLONE | `$DISPATCH`, deepseek — then YOU run the suite and verify green |
| 8 | Improve tests | You or agent | `references/auto-improve-tests.md` |
| 9 | **Code review — adversarial** | Other-corpus agent (+ [[conejo-merge]] once PR'd) | reviewer prompt must REFUTE, never admire |
| 10 | Loop | — | next feature stacks a PR on this one |

Rules that ride along:

- IF a review stage (2, 4, 9) returns only praise THEN it's a null result — re-dispatch
  with a harsher prompt or a different model. Zero credit for praise.
- IF an agent finished THEN read its conclusion/diff, NOT its transcript. Transcripts
  stay in /tmp; conclusions enter your context.
- Don't be afraid of sending several agents: split the tasks as much as possible —
  up to 20 in parallel, one discrete unit each.
- NEVER let two agents write to the same directory — clone/worktree first.
- PR over PR ALWAYS. Push. After it is at GitHub, clean their mess.
- PRESERVE your context no matter what. Other-corpus agents first (different
  perspectives); if the work must be done anyway, send YOUR agents. Don't pollute
  your context.

### Canonical dispatch commands

opencode (per-call `--model` — the corpus-diversity workhorse):

```bash
nohup opencode run "$PROMPT" \
  --model <family>/<biggest-available-version> \
  --dangerously-skip-permissions \
  --dir "$WORKDIR" \
  > /tmp/oc-$NAME.log 2>&1 &
```

crush (model comes from crush's own config):

```bash
nohup crush run -q -y --cwd "$WORKDIR" "$PROMPT" > /tmp/crush-$NAME.log 2>&1 &
```

Then set the timer and poll — NOBODY wakes you up. Cap the wait at **10 minutes**:

```bash
# Poll every ~60s; stop at 10m wall-clock even if the agent is still silent
sleep 60; tail -20 /tmp/oc-$NAME.log   # repeat until done-marker OR 10 minutes elapsed
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

| IF | THEN model |
|---|---|
| Default — spec review | `zai-coding-plan/glm-5.1` (smartest but slow) |
| Default — plan review / failing tests / implement | `deepseek/deepseek-v4-pro` |
| User wants a different POV, contrarian take, "what would X say", or distrusts a single model | `minimax-coding-plan/minimax-m3` (fast M3 coding plan) |
| User is "poor" (budget-constrained, signals `cheap`/`free`/`avoid paid`) | `alibaba-coding-plan/qwen-3.7-max` — always substitute the biggest available model of the family (`qwen-3.7-max` → `qwen-4-max` if released) |
| Last resort | vanilla `minimax` |

IF swapping models for a stage THEN dispatch **2–4 agents in parallel** (one per family)
and judge: winner merges, runners-up get their best ideas grafted. Never sequentialize.

## Testing — READ FIRST

The universal red-green doctrine is canonical in `references/testing-doctrine.md`.
Backend/logic/CLI/library use `vitest`; UI behavior uses agent-browser click-flows
(see [[conejo-frontend]]). Never implement before a failing test. RED must fail for the
RIGHT reason (assertion failure, not an import error).

## Standards & helpers

- Coding standards: `references/coding-standards.md` (+ `-api-design.md`, `-testing.md`).
- Dependency hygiene (bun): `references/deps-check.md`.
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

## Tooling

bun (not npm) · vitest (not jest, not `bun test`) · vite-plus (`vp`) for build/check · ESM only.
