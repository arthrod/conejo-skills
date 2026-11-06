# Agent dispatch — the Warren Protocol (canonical)

One rabbit digging alone fills its own burrow with dirt. The warren digs in parallel
and every tunnel stays clean. This is the canonical doctrine for delegating work to
other agents. Authored once, referenced by every conejo-* skill and by the
`<!-- conejo -->` blocks inside the vendored superpowers skills.

## The two laws (why we delegate at all)

1. **Context is sacred.** Your context window is the project's working memory. Every
   file dump, test log, or review transcript you read inline is memory you never get
   back. Delegate the reading/reviewing/implementing; keep only the conclusions. You
   are the orchestrator — stay clean-headed.
2. **Different corpus, different eyes (hidden gems).** A model trained on a different
   corpus knows things yours doesn't: a deprecation, a locale trap, a CVE-adjacent
   pattern, a flag that silently changed semantics in v3. Adversarial disagreement
   between agents is signal, not noise. One model reviewing its own work is a rabbit
   grading its own carrot count.

## The rule of the second corpus (STRICT — Arthur, 2026-11-06)

Every second opinion — spec review, plan review, code review, debugging hypotheses,
PR-comment verification — comes from a model that is **not** the model that produced
the work. "Another point of view" means another corpus, not another instance.

| Who produced the work | Who reviews it |
|---|---|
| You (Claude, this session) | GLM / MiniMax / DeepSeek via `pi` or `crush`; GPT via `codex`; Grok via `grok` |
| A dispatched zai/GLM agent | MiniMax or DeepSeek via `pi`; GPT via `codex`; Grok via `grok`; a Claude subagent |
| A dispatched GPT (`codex`) agent | GLM via `pi`/`crush`; Grok via `grok`; a Claude subagent |
| A dispatched Grok agent | GLM/MiniMax via `pi`; GPT via `codex`; a Claude subagent |
| Anyone | never the same family that wrote it |

Same-corpus Claude subagents (the harness Agent tool) are the **last rung** for
reviews. Use them freely for *work* where corpus doesn't matter (implementing from a
brief, mechanical edits, log reading). When you must use them for review, give each a
different lens (correctness / security / performance / "does it reproduce") — perspective
diversity is the poor rabbit's corpus diversity.

## Step 0 — resolve the dispatchers (ONCE per session)

Probe once. Keep EVERY tool that answers — each one is a corpus you can call on demand.

```bash
for c in pi crush codex grok cline octo opencode gemini; do
  command -v "$c" >/dev/null 2>&1 && echo "HAVE $c" || echo "miss $c"
done
```

Default order when you have no corpus preference: **pi → crush → codex → grok → cline
→ octo → subagents**. (This machine, 2026-11-06: pi 1.5.0, crush v0.99.0, codex 0.166.0,
grok 1.0.77, cline 3.0.74, octo/octofriend 0.0.60 installed; opencode and gemini not.)

NEVER conclude "no agents available, I'll do everything inline." That torches your
context and forfeits the second pair of eyes. The ladder always terminates: subagents
always exist.

## Tool cheat-sheet — list the models, pick one, run headless

Flags drift; the ladder doesn't. IF a command is rejected THEN `<cli> --help` (or
`<cli> <subcommand> --help`), re-map, retry once. Verified on this machine 2026-11-06.

### pi — default workhorse (most corpora per call)

- **List scoped models** (the ones enabled in `~/.pi/agent/settings.json`): `pi-help`
  (zsh function in `~/.zshrc`).
- **List every model pi knows:** `pi --list-models [search]` — e.g. `pi --list-models glm`.
- **Select per call:** `--provider <name> --model <id>` (or `--model provider/id`,
  optional `:<thinking>` suffix, e.g. `--model zai/glm-5.3:high`).
- **Headless:**

```bash
( cd "$WORKDIR" && nohup pi --provider zai --model glm-5.3 --no-session \
    -p "$PROMPT" < /dev/null > /tmp/pi-$NAME.log 2>&1 & )
```

  `< /dev/null` matters when backgrounded — pi otherwise hangs on stdin.
- **Corpora scoped today:** `zai/glm-5.3`, `zai/glm-5.3-highspeed`, `zai/glm-5.3-flash`,
  `minimax/MiniMax-M3`, `nvidia/deepseek-ai/deepseek-v4.1-flash`, `nvidia/z-ai/glm-5.3-flash`,
  `xai/grok-4.7`, `meta/muse-spark-1.3-contributor`,
  `synthetic/hf:deepseek-ai/DeepSeek-V4.1-Flash-1017`.

### crush

- **List:** `crush models [search]` — `provider/model` lines; unconfigured providers are
  marked `(not configured)`. `crush models glm` filters. Providers live in
  `~/.config/crush/crush.json` (zai is configured here).
- **Select per call:** `-m <model>` or `-m <provider/model>` on `crush run`;
  `--small-model` for the helper model; `--reasoning-effort low|medium|high`.
- **Headless:**

```bash
nohup crush run -q -c "$WORKDIR" -m zai/glm-5.3 "$PROMPT" > /tmp/crush-$NAME.log 2>&1 &
```

  No `-y`: `--yolo` is a root-TUI flag and `crush run` rejects it ("Unknown shorthand
  flag: 'y'"), aborting the dispatch before the agent starts.

### codex — OpenAI corpus

- **List:** no list subcommand. `/model` inside the interactive TUI shows the picker;
  the default is `model = "<id>"` in `~/.codex/config.toml` (today `gpt-6-astra`).
- **Select per call:** `-m <model>` (or `-c model="<model>"`); reasoning via
  `-c model_reasoning_effort="high"`.
- **Headless** (non-interactive mode is `codex exec`; there is no `--full-auto` in 0.166.0):

```bash
( cd "$WORKDIR" && nohup codex exec -m gpt-6-astra -s workspace-write --approve-for-me \
    "$PROMPT" > /tmp/codex-$NAME.log 2>&1 & )
```

  `-s read-only` for pure reviews. `--dangerously-bypass-approvals-and-sandbox` only
  inside a throwaway clone.

### grok — xAI corpus

- **List:** `grok models` (prints the default and the ids — today `grok-4.7`,
  `grok-4.7-build-fast`, `grok-4.6`, `grok-4.5`).
- **Select per call:** `-m <model>`; `--reasoning-effort <effort>`.
- **Headless** (`-p`/`--single` prints the answer and exits):

```bash
( cd "$WORKDIR" && nohup grok -m grok-4.7 --permission-mode bypassPermissions --no-subagents \
    -p "$PROMPT" > /tmp/grok-$NAME.log 2>&1 & )
```

  `--permission-mode plan` or `--disallowed-tools` for read-only reviews.

### cline

- **List / configure:** `cline auth [provider]` — interactive provider → model picker
  (needs a TTY); non-interactively `cline auth -p <provider> -m <model-id> -k <key>`.
  `cline config` shows the current configuration (TTY).
- **Select per call:** `-P <provider-id> -m <model-id>`; `--thinking low|medium|high|xhigh`.
- **Headless** (a bare prompt runs in act mode; `-y` auto-approves a limited tool set;
  note `-p` is PLAN mode, not "print"):

```bash
( cd "$WORKDIR" && nohup cline -y -c "$WORKDIR" -P <provider> -m <model> \
    "$PROMPT" > /tmp/cline-$NAME.log 2>&1 & )
```

  `--worktree` makes cline create its own detached worktree under `~/.cline/worktrees/`.

### octo (octofriend)

- **List:** `octo list` — the nicknames in `~/.config/octofriend/octofriend.json5`
  (today three Synthetic-hosted models, incl. `GLM 5.3 Flash (Synthetic)`).
- **Select per call:** `--model "<nickname>"` on `octo prompt`.
- **Headless:** `octo prompt --model "GLM 5.3 Flash (Synthetic)" "$PROMPT" > /tmp/octo-$NAME.log 2>&1`.
  `prompt` is single-shot chat — reviews, judgments, second opinions — not an agentic
  file-editing run. For agentic work use interactive `octo --unchained` or another tool.

### Subagents (harness Agent tool) — the fallback, not the default

Same corpus as you. Same discipline as the CLIs:

- One discrete unit per subagent; self-contained prompt (paths, expected output,
  acceptance criteria and their measurers).
- Launch all independent subagents in ONE message so they run in parallel.
- Subagents that WRITE files get worktree isolation. Read-only reviewers can share.
- Only the subagent's final report enters your context. That is the whole point.
- Compensate for the shared corpus with **perspective diversity** and an adversarial
  charter.

## Model preferences (when the CLI takes a model)

Run `pi-help` for the live scoped list and favor the best Chinese models among them;
reach for `codex`/`grok` when you need a corpus that is neither Claude nor Chinese.

| Situation | Model (tool) |
|---|---|
| Default — spec / design review | `zai/glm-5.3` (pi or crush) — smartest, slow |
| Default — plan review, failing tests, implement | `zai/glm-5.3-highspeed` (pi) |
| Second corpus / contrarian / user distrusts one model | `minimax/MiniMax-M3` (pi) |
| Third corpus for a tie-break | `gpt-6-astra` (codex) or `grok-4.7` (grok) |
| Budget-constrained ("cheap", "free", "poor") | `zai/glm-5.3-flash` (pi), `nvidia/z-ai/glm-5.3-flash` (pi), or `GLM 5.3 Flash (Synthetic)` (octo) |
| DeepSeek corpus specifically | `nvidia/deepseek-ai/deepseek-v4.1-flash` (pi) — see memory: stalls in `pi -p`; prefer glm/MiniMax when it hangs |
| Last resort | any scoped method from `pi-help`; then subagents |

Always substitute the **biggest available model of the same family** (`glm-5.3` →
`glm-5.4` the day it exists). IF swapping models for a stage THEN dispatch 2–4 agents in
parallel (one per family) and judge; never sequentialize.

## Dispatch hygiene (non-negotiable)

- **Discrete units.** Split the task as small as it will split; one agent per unit;
  up to 20 in parallel. Don't be afraid of the swarm — that's what a warren is.
- **Never share a writable dir.** Two agents writing one checkout = warren collapse.
  Clone, copy, or `git worktree add "$WORKDIR" -b agent/$NAME` first.
- **Self-contained prompts.** The agent knows NOTHING you don't tell it: file paths,
  versions, acceptance criteria + measurers, output format, and "write your final
  answer to <file>".
- **Adversarial framing for reviewers.** Reviewer prompts MUST say: "Find what is
  wrong. Try to refute the approach. You get zero credit for praise. If you cannot
  refute, state exactly what you tried." IF a reviewer returns only praise THEN
  re-dispatch with a harsher prompt or a different corpus — praise is a null result.
- **Reviewers run the measurers.** A reviewer that was given acceptance criteria runs
  each criterion's independent measurer and reports the output; "looks right in the
  diff" is not a verdict. Doctrine: `references/acceptance-criteria.md`.
- **Diversity for generators.** When generating (specs, plans, implementations),
  dispatch 2–4 with different framings/models, then judge: pick the winner and graft
  the runners-up's best ideas. The gems hide in the losing drafts too.
- **Timers, ALWAYS.** NOTHING will wake you up — not the user, not Claude agents, not
  pi, crush, codex, grok, cline, octo, forge, not **@coderabbitai**. After dispatching
  (or tagging a bot), poll yourself:

```bash
# Poll every ~60s. Cap the wait at 10 minutes wall-clock.
sleep 60; tail -20 /tmp/pi-$NAME.log   # repeat until done-marker OR 10m elapsed
# For GitHub bots (CodeRabbit etc.):
# sleep 60; gh issue/pr view … --json comments  # same 10m cap
```

- **Max wait: 10 minutes.** Cap every wait on another agent or bot at **10 minutes**.
  IF the reply is still missing at 10m THEN stop waiting: proceed on best efforts with
  what you have, keep going diligently and calmly, and leave a short note (issue/PR
  comment or ledger line) that you proceeded without the reply. Never block the plan
  on a silent agent. CI/CD is a special case: you don't wait for it at all unless you
  are on the plan's last task — `references/stacked-prs-and-ci.md`.
- **Collect → dedupe → judge → integrate.** Read the agents' conclusions and diffs,
  never their transcripts. Reconcile disagreements with evidence (run the test, run the
  measurer, read the dependency source), not with vibes.

## When NOT to delegate

- IF the edit is < ~5 lines and you already hold all the context → just do it, THEN
  still get the other-corpus review if it ships.
- IF the task needs accumulated session context that won't compress into a prompt →
  do it yourself, THEN dispatch an adversarial other-corpus review of what you did.
- IF the worktree contains secrets/credentials or client PII → do NOT ship it to
  third-party model CLIs (memory: PII pre-authorization). Use subagents (same trust
  domain) instead, or scrub first.
