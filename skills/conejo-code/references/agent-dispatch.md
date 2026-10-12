# Agent dispatch — the Warren Protocol (canonical)

One rabbit digging alone fills its own burrow with dirt. The warren digs in parallel
and every tunnel stays clean. This is the canonical doctrine for delegating work to
other agents. Authored once, referenced by every conejo-* skill.

## The two laws (why we delegate at all)

1. **Context is sacred.** Your context window is the project's working memory. Every
   file dump, test log, or review transcript you read inline is memory you never get
   back. A rabbit that reads every transcript ends the sprint very well-informed and
   completely out of head-room. Delegate the reading/reviewing/implementing; keep only
   the conclusions. You are the orchestrator — stay clean-headed.
2. **Different corpus, different eyes (hidden gems).** A model trained on a different
   corpus knows things yours doesn't: a deprecation, a locale trap, a CVE-adjacent
   pattern, a flag that silently changed semantics in v3. Adversarial disagreement
   between agents is signal, not noise. One model reviewing its own work is a rabbit
   grading its own carrot count.

## Step 0 — Resolve your dispatcher (the ladder)

Probe ONCE per session, in this exact order. First hit wins.

```bash
if   command -v pi       >/dev/null 2>&1; then DISPATCH=pi
elif command -v crush    >/dev/null 2>&1; then DISPATCH=crush
elif command -v opencode >/dev/null 2>&1; then DISPATCH=opencode
elif command -v codex    >/dev/null 2>&1; then DISPATCH=codex
elif command -v gemini   >/dev/null 2>&1; then DISPATCH=gemini
else DISPATCH=subagents; fi
echo "DISPATCH=$DISPATCH"
```

- IF `pi` found → Template A — the default workhorse. Per-call `--provider`/`--model`
  gives corpus diversity on demand; list scoped methods with `pi-help` (or
  `pi --list-models`) and FAVOR THE BEST CHINESE MODELS available among them
  (`zai/glm-5.3` flagship, `minimax/MiniMax-M3` second corpus, `zai/glm-5.3-highspeed`
  fast lane). Details: [[pi-using]].
- ELIF `crush` found → Template B.
- ELIF `opencode` found → Template C (per-call `--model` = corpus diversity on demand).
- ELIF `codex` / `gemini` found → run `<cli> --help | head -40`, find its
  non-interactive mode (`run` / `exec` / `-p`), map it onto Template D.
- ELSE → subagents, Template E. Subagents ARE your Claude fallback — spawning a second
  `claude -p` adds nothing over them, and subagents get better harness integration
  (parallelism, worktrees, completion notifications).
- IF pi is missing and BOTH crush and opencode exist → prefer opencode when you need
  per-call model switching (a genuinely different corpus for a review); crush otherwise.
- NEVER conclude "no agents available, I'll do everything inline." That torches your
  context and forfeits the second pair of eyes. The ladder always terminates: subagents
  always exist.

## Command templates

External dispatches are ALWAYS backgrounded, logged, and polled. NEVER foreground-block.

**Template A — pi** (per-call `--provider`/`--model`; the default workhorse.
Scoped methods + launch syntax: run `pi-help`. Favor the best Chinese models —
`zai/glm-5.3` smart, `zai/glm-5.3-highspeed` fast, `minimax/MiniMax-M3` second corpus):

```bash
( cd "$WORKDIR" && nohup pi --provider zai --model glm-5.3 --no-session \
    -p "$PROMPT" > /tmp/pi-$NAME.log 2>&1 & )
```

**Template B — crush** (model comes from crush's own config). The invocation is
`crush run [prompt...]` — prompt as arguments or on stdin, run in the CURRENT
directory, so `cd` first:

```bash
cd "$WORKDIR" && nohup crush run --quiet "$PROMPT" > /tmp/crush-$NAME.log 2>&1 &
```

No `-y`, no `--cwd` — `-y` dies with "Unknown shorthand flag: 'y'" and the dispatch
never starts. `--quiet` (not `-q`) hides the spinner. Check `crush run --help` if a
flag is rejected rather than guessing.

**Template C — opencode** (per-call model; the corpus-diversity workhorse):

```bash
nohup opencode run "$PROMPT" \
  --model <family>/<biggest-available-version> \
  --dangerously-skip-permissions \
  --dir "$WORKDIR" \
  > /tmp/oc-$NAME.log 2>&1 &
```

**Template D — other agent CLIs** (verify flags with `--help` before first use; the
shapes that usually work):

```bash
( cd "$WORKDIR" && nohup codex exec --full-auto "$PROMPT" > /tmp/codex-$NAME.log 2>&1 & )
( cd "$WORKDIR" && nohup gemini -y -p "$PROMPT"           > /tmp/gem-$NAME.log   2>&1 & )
```

IF any command errors on a flag → `<cli> --help`, re-map,
retry once. Flags drift; the ladder doesn't. Don't abandon delegation over a flag.

**Template E — subagents (no CLI found).** Use your harness's subagent mechanism
(Claude Code: the Agent tool). Same discipline as the CLIs:

- One discrete unit per subagent; self-contained prompt (paths, expected output,
  acceptance criteria).
- Launch all independent subagents in ONE message so they run in parallel.
- Subagents that WRITE files get worktree isolation (or a per-agent clone). Read-only
  reviewers can share.
- Only the subagent's final report enters your context. That is the whole point.
- Same corpus, so compensate with **perspective diversity**: give each subagent a
  different lens (correctness / security / performance / "does it reproduce") and an
  adversarial charter. Diverse lenses are the poor rabbit's diverse corpora.

## Model preferences (when the CLI takes `--model`, i.e. pi and opencode)

Run `pi-help` (zsh function; elsewhere `pi --list-models`) and favor the best CHINESE
models available among the scoped methods:

| Situation | Model |
|---|---|
| Default — specs/brainstorm review | `zai/glm-5.3` (smartest, slow) |
| Default — plan review, failing tests, implement | `zai/glm-5.3-highspeed` (fast lane) |
| User wants a different POV / contrarian / distrusts one model | `minimax/MiniMax-M3` |
| User is budget-constrained ("cheap", "free", "poor") | `zai/glm-5.3-flash` (or `nvidia/z-ai/glm-5.3-flash`) |
| DeepSeek corpus specifically | `nvidia/deepseek-ai/deepseek-v4.1-flash` |
| Last-resort fallback | any scoped method from `pi-help` |

Always substitute the **biggest available model of the same family** (`glm-5.3` →
`glm-5.4` the day it exists). IF swapping models for a stage → dispatch 2–4 agents in
parallel (one per family) and judge; never sequentialize.

## Dispatch hygiene (non-negotiable)

- **Discrete units.** Split the task as small as it will split; one agent per unit;
  up to 20 in parallel. Don't be afraid of the swarm — that's what a warren is.
- **Never share a writable dir.** Two agents writing one checkout = warren collapse.
  Clone, copy, or `git worktree add "$WORKDIR" -b agent/$NAME` first.
- **Self-contained prompts.** The agent knows NOTHING you don't tell it: file paths,
  versions, acceptance criteria, output format, and "write your final answer to <file>".
- **Adversarial framing for reviewers.** Reviewer prompts MUST say: "Find what is
  wrong. Try to refute the approach. You get zero credit for praise. If you cannot
  refute, state exactly what you tried." IF a reviewer returns only praise THEN
  re-dispatch with a harsher prompt or a different model — praise is a null result.
- **Diversity for generators.** When generating (specs, plans, implementations),
  dispatch 2–4 with different framings/models, then judge: pick the winner and graft
  the runners-up's best ideas. The gems hide in the losing drafts too.
- **Timers, ALWAYS.** NOTHING will wake you up — not the user, not Claude agents, not
  opencode, not crush, not forge, not **@coderabbitai**. After dispatching (or tagging
  a bot), poll yourself:

```bash
# Poll every ~60s. Cap the wait at 10 minutes wall-clock.
sleep 60; tail -20 /tmp/pi-$NAME.log   # repeat until done-marker OR 10m elapsed
# For GitHub bots (CodeRabbit etc.):
# sleep 60; gh issue/pr view … --json comments  # same 20m cap
```

- **Max wait: 10 minutes.** Cap every wait on another agent at **10 minutes** —
  especially @coderabbitai (also Jules, Gemini, crush, opencode, forge, or any other
  bot/agent). IF the reply is still missing at the 20m mark THEN **stop waiting**:
  proceed on best efforts with what you have, keep going diligently and calmly, and
  leave a short note (issue/PR comment or session log) that you proceeded without the
  reply. Never block the plan forever on a silent agent. Prefer partial progress over
  an infinite poll.

- **Collect → dedupe → judge → integrate.** Read the agents' conclusions and diffs,
  never their transcripts. Reconcile disagreements with evidence (run the test, read
  the dependency source), not with vibes.

## When NOT to delegate

- IF the edit is < ~5 lines and you already hold all the context → just do it.
- IF the task needs accumulated session context that won't compress into a prompt →
  do it yourself, THEN dispatch an adversarial review of what you did.
- IF the worktree contains secrets/credentials → do NOT ship it to third-party model
  CLIs. Use subagents (same trust domain) instead.
