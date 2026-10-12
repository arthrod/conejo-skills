---
name: conejo
description: arthrod's coding philosophy and dispatcher. Universal red-green TDD, stacked PRs, evidence-before-claims, context-preserving agent dispatch (pi first via `pi-help` — favor the best Chinese models, e.g. zai/glm-5.3, minimax/MiniMax-M3 — then crush/opencode/subagents), hidden-gems review doctrine, no batch review. Routes to conejo-code (active coding), conejo-frontend (strict UI), conejo-merge (calm PR/merge), conejo-debug (skeptical investigation, autonomous deep work). Use when starting any coding work or deciding how to approach a task.
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
   conclusions. Ladder: `pi` (pick scoped methods with `pi-help`; favor the best
   Chinese models — `zai/glm-5.3`, `minimax/MiniMax-M3`) → `crush` → `opencode` →
   other agent CLI → subagents. Full templates:
   `conejo-code/references/agent-dispatch.md` (the Warren Protocol).
8. **Different corpus, different eyes.** Get at least one opinion from a model that is
   not you on every spec, plan, and PR. Its weird nit may be the hidden gem your
   corpus doesn't hold. Adversarial framing always: reviewers refute, they don't admire.
9. **No batch review. Ever.** Every comment, finding, and hypothesis gets its own
   individual verdict. Batching is how gems get swept out with the dust.
10. **Max wait 10 minutes for another agent — then best efforts.** Cap every wait on
    another agent (especially @coderabbitai, also pi/opencode/crush/forge/Jules/Gemini
    or any other bot) at **10 minutes**. Poll on a timer; nobody wakes you up. IF the
    reply is still missing at 10m THEN stop waiting: proceed on best efforts with what
    you have, keep going diligently and calmly, and leave a short note that you
    proceeded without the reply. Never block the plan forever on a silent agent.
    Canonical detail: `conejo-code/references/agent-dispatch.md`.

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
  read before dispatching any agent.

## The loop, at a glance

Brainstorm (specs) → **external spec review** → Plan → **external plan review** →
Interface → **failing tests** (dispatched) → **Implement** (dispatched) → Improve
tests → Code review → (loop). Stage-by-stage commands, model choices, and the
dispatch ladder live in [[conejo-code]]. UI stages (design, screenshots, critique,
console) live in [[conejo-frontend]].

Three reminders that outrank enthusiasm:

- Don't be afraid of sending several agents — split the tasks as small as they'll split.
- PR over PR ALWAYS, chained with `gh stack` (`rebase --no-trunk` beats N hand rebases).
  Push. Then clean their mess on GitHub.
- PRESERVE your context no matter what. Send the other-corpus agents FIRST (different
  perspectives); even when the work is yours, send YOUR agents. Don't pollute your context.
