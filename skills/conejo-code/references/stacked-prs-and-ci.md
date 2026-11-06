# Stacked PRs and CI/CD — when to push, when to wait (canonical)

Authored once here; referenced by writing-plans, executing-plans,
subagent-driven-development, finishing-a-development-branch, requesting-code-review,
receiving-code-review and every conejo-* skill. The full `gh stack` command set and
merge-order rules also live in `conejo-merge/refs/pr-triage.md`.

## Stacked PRs — GitHub supports them natively; we use them ALWAYS

A **stack** is a chain of branches, each based on the one below it, each with its own
pull request whose base is the previous branch. GitHub's own `gh stack` extension
(v0.2.1 here) manages the chain, and GitHub renders the stack on every PR in it.
Reviewers see one small, reviewable diff per PR instead of a 3,000-line PR; CI runs
per layer; a bad layer is fixed in place and the layers above are rebased in one
cascade. That is why: small diffs get real review, and real review finds hidden gems.

Explain this to your human partner the first time it comes up in a project — one
paragraph, then do it.

Rules:

1. **PR over PR, ALWAYS.** One plan → one stack. One task (or one task group with a
   single reviewable theme) → one branch → one PR layer. Never pile a second feature
   onto a PR that is waiting for review.
2. **Never hand-rebase the chain.** `gh stack rebase --no-trunk` cascades every layer
   onto the one below it; `--continue` / `--abort` ride through conflicts.
3. **Push early, push often.** After each task's commit: `gh stack push` (or `gh stack
   submit` the first time, which opens the PRs). Then start the next task — do not wait
   for anything (CI rule below).
4. **Clean their mess on GitHub afterward:** PR titles/bodies, retargets, merge order —
   `conejo-merge/refs/pr-triage.md`. Native stacks are merged with `gh stack merge`;
   their PRs refuse `gh pr edit --base` and plain `gh pr merge` by design.

Commands (gh-stack v0.2.1):

```bash
gh extension install github/gh-stack   # once
gh stack init                          # start a stack from the current branch (targets the default branch)
gh stack init b1 b2 b3                 # adopt existing branches as one stack, bottom → top
gh stack add <branch>                  # after committing: add a new layer on top
gh stack submit                        # push + create/update every PR in the stack
gh stack push                          # push all active branches
gh stack rebase --no-trunk             # cascade each layer onto the one below (keeps main out of it)
gh stack rebase --continue             # after resolving a conflict
gh stack rebase --abort                # restore every branch
gh stack sync                          # pull remote state
gh stack view                          # show the stack
gh stack checkout <n | PR | branch>    # jump to a layer
gh stack merge                         # merge the whole stack bottom-up
gh stack link                          # link already-open PRs into a stack on GitHub
gh stack modify | unstack              # restructure / dissolve
```

Plan-time mapping (writing-plans): every task carries a `**Stack:**` line naming its
branch and its base (the previous task's branch, or `main` for Task 1). Execution
(executing-plans / SDD): the task's last step is commit → `gh stack add` (first time)
or `gh stack push`.

## CI/CD — wait only on the LAST task

Arthur, 2026-11-06: **wait for CI/CD only if it is the last task.**

- IF you just finished task N of M with N < M THEN commit, push the stack, and start
  task N+1 immediately. Do NOT poll GitHub Actions, CodeRabbit, Jules, Gemini or any
  other bot. Their results are inputs for later, not gates for now.
- IF you just finished the **last** task THEN push, and NOW wait for CI and the bots —
  with the 10-minute cap and the 60-second poll from `agent-dispatch.md`. Then handle
  every PR comment one by one (`conejo-merge` Phase 5; the ledger must reconcile).
- IF CI on an earlier layer went red while you were working THEN it becomes a finding
  for the task that owns that layer: fix it in that layer (red-green), `gh stack rebase
  --no-trunk`, push, continue. Don't stop the plan to babysit it.
- IF CI never starts (memory: arthrod's private repos have GitHub-hosted runners blocked
  on billing; the self-hosted netcup runners have been offline) THEN that is not a
  failure to wait on. Note it in the ledger, keep the local suite + measurers as the
  evidence, proceed.
- **Local verification is never skipped because CI exists.** Run the suite and every
  acceptance measurer (`acceptance-criteria.md`) locally BEFORE every push. CI is the
  second grader, not the first.
- Waiting for the human partner is a different thing: only the four stops in
  executing-plans / SDD stop a running plan.

## PR comments — one by one, ALWAYS

Every time you are dealing with a PR — yours, a bot's, a teammate's, a stack layer,
a re-review — you reply **one comment at a time**, each with its own verdict
(`implement` / `push back` / `duplicate-of-#N`) and its own reply, and the count must
reconcile: `implemented + pushed-back + duplicate-linked == total`. Never sample,
summarize, or "handle the important ones" — that is how hidden gems get swept out with
the dust. The procedure, the gate, and the reply shapes are `conejo-merge` Phase 5;
the mindset is `receiving-code-review`.
