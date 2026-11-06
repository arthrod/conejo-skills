---
name: conejo
description: arthrod's coding philosophy and dispatcher. Universal red-green TDD, acceptance criteria with independent measurers on every task, stacked PRs via `gh stack`, evidence-before-claims, context-preserving agent dispatch to OTHER-corpus models (pi → crush → codex → grok → cline → octo → subagents; `pi-help` for scoped models, favor zai/glm-5.3 and minimax/MiniMax-M3; the reviewer is never the author's corpus), CI/CD wait only on the last task, hidden-gems review doctrine, one-by-one PR replies, no batch review. Routes to conejo-code (active coding), conejo-frontend (strict UI), conejo-merge (calm PR/merge), conejo-debug (skeptical investigation, autonomous deep work). Use when starting any coding work or deciding how to approach a task.
---

# Conejo — the coding philosophy

Conejo is how we build. Small on purpose: the non-negotiables, the routing table, done.
One rabbit, many burrows.

## Non-negotiables

1. **Red-green TDD, always — backend and frontend alike.** Write the failing test,
   watch it fail for the right reason, write the minimum to pass, refactor under green.
   No implementation before a failing test. See [[test-driven-development]].
2. **Test always. No exceptions.** IF you cannot write a test THEN you do not yet
   understand the problem — go understand it first.
3. **Stacked PRs, driven by `gh stack` — never hand-rebase the chain.** Branch over
   branch; PR often; each PR over its predecessor. Push early. After it's on GitHub,
   clean their mess. Install once (`gh extension install github/gh-stack`), adopt
   existing branches with `gh stack init b1 b2 b3` (bottom to top), and let
   `gh stack rebase --no-trunk` rebase every branch onto the one below it in one
   cascade (`--continue`/`--abort` ride through conflicts). Full command set:
   `conejo-merge/refs/pr-triage.md`.
4. **Brainstorm before building** anything non-trivial. See [[brainstorming]].
5. **Debug systematically**, never by guessing. See [[systematic-debugging]] and
   [[conejo-debug]].
6. **Evidence before claims.** Never say "done/fixed/passing" without running the
   verification and showing output. See [[verification-before-completion]].
7. **Context is sacred — delegate.** Your context window is the project's working
   memory. Dispatch reading/implementing/reviewing to other agents and keep only their
   conclusions. Ladder: `pi` (scoped models via `pi-help`; favor the best Chinese
   models — `zai/glm-5.3`, `minimax/MiniMax-M3`) → `crush` → `codex` → `grok` →
   `cline` → `octo` → subagents. How to list and select each tool's models, and the
   headless command per tool: `conejo-code/references/agent-dispatch.md` (the Warren
   Protocol).
8. **Different corpus, different eyes — STRICT.** Every review (spec, plan, code, PR
   comment verification, debugging hypotheses) comes from a model that is NOT the
   model that produced the work: GLM/MiniMax/DeepSeek via pi or crush, GPT via codex,
   Grok via grok. Same-corpus subagents review only as the last rung. Its weird nit
   may be the hidden gem your corpus doesn't hold. Adversarial framing always:
   reviewers refute, they don't admire.
9. **No batch review. Ever.** Every comment, finding, and hypothesis gets its own
   individual verdict. Batching is how gems get swept out with the dust.
10. **Max wait 10 minutes for another agent — then best efforts.** Cap every wait on
    another agent (especially @coderabbitai, also pi/opencode/crush/forge/Jules/Gemini
    or any other bot) at **10 minutes**. Poll on a timer; nobody wakes you up. IF the
    reply is still missing at 10m THEN stop waiting: proceed on best efforts with what
    you have, keep going diligently and calmly, and leave a short note that you
    proceeded without the reply. Never block the plan forever on a silent agent.
    Canonical detail: `conejo-code/references/agent-dispatch.md`.
11. **Acceptance criteria on every plan task — ALWAYS, no exceptions — each with an
    independent measurer.** A criterion is an observable behavior plus the command,
    probe, click-flow, diff or metric that proves it from outside the code; reading
    the diff is review, not measurement. Measurers go red before and green after, the
    reviewer runs them, the ledger records their output.
    `conejo-code/references/acceptance-criteria.md`.
12. **Wait for CI/CD only on the LAST task.** Middle of a plan: commit, `gh stack
    push`, next task — no polling of Actions or bots. Last task: wait (10-minute cap),
    then handle every PR comment one by one. If the runners never start (billing),
    local suite + measurers are the evidence.
    `conejo-code/references/stacked-prs-and-ci.md`.
13. **Every PR interaction is one comment at a time.** Own verdict, own reply, ledger
    reconciles. Without exception — that is how hidden gems survive. [[conejo-merge]].

## Dispatch (IF this, THEN that)

| IF you are… | THEN use |
|---|---|
| Writing/changing code (logic, services, APIs, libraries, CLIs) | **[[conejo-code]]** |
| Building or changing any web UI | **[[conejo-frontend]]** (strict; includes the conejo-code base) |
| Implementing/answering PR comments, merging, triaging PRs | **[[conejo-merge]]** |
| Hunting bugs, interrogating suspicious PRs, autonomous deep work on something hard | **[[conejo-debug]]** |
| Genuinely unsure | Start at [[conejo-code]]; it routes onward. |

Doctrines are authored ONCE and referenced everywhere:

- **Testing doctrine:** `conejo-code/references/testing-doctrine.md` — read before
  writing any test. conejo-frontend adds the UI superset.
- **Agent dispatch (Warren Protocol):** `conejo-code/references/agent-dispatch.md` —
  read before dispatching any agent; it lists how to see and pick each tool's models.
- **Acceptance criteria / independent measurers:**
  `conejo-code/references/acceptance-criteria.md` — read before writing or executing
  any plan task.
- **Stacked PRs and CI/CD:** `conejo-code/references/stacked-prs-and-ci.md` — read
  before pushing, opening a PR, or deciding whether to wait on CI.
- **Oxlint / oxfmt:** `conejo-code/references/oxlint.md` — read before adding or
  changing TS/JS lint or format config.

## Stack preference (house tooling)

pnpm (never npm/bun/yarn) · uv (never pip/poetry) · pyrefly for Python types · ruff
for Python lint/format · oxlint + oxfmt for TS/JS (not biome/eslint/prettier) · vite +
vitest (not jest) · Astro for sites · cargo-nextest for Rust tests · `mbx setup` once so plain
cargo runs through mbx (shared, self-pruning build cache — output and target dirs don't
explode context) · every project has
a complete README.md with badges, tagged semver releases, and packages published via
OIDC trusted publishing (npm, PyPI, crates.io) — no long-lived tokens. Canonical list:
`~/.claude/CLAUDE.md`.

## The loop, at a glance

Brainstorm (specs + acceptance criteria) → **other-corpus spec review** → Plan (every
task: acceptance criteria + measurer + stack layer) → **other-corpus plan review** →
Interface → **measurers RED, failing tests RED** (dispatched) → **Implement** (dispatched)
→ tests GREEN, measurers GREEN → Improve tests → **other-corpus code review** → commit,
`gh stack push`, next task (CI only after the last) → (loop). Stage-by-stage commands, model choices, and the
dispatch ladder live in [[conejo-code]]. UI stages (design, screenshots, critique,
console) live in [[conejo-frontend]].

Three reminders that outrank enthusiasm:

- Don't be afraid of sending several agents — split the tasks as small as they'll split.
- PR over PR ALWAYS, chained with `gh stack` (`rebase --no-trunk` beats N hand rebases).
  Push. Then clean their mess on GitHub.
- PRESERVE your context no matter what. Send the other-corpus agents FIRST (different
  perspectives); even when the work is yours, send YOUR agents. Don't pollute your context.
