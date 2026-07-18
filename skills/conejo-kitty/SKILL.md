---
name: conejo-kitty
description: Policy for handling local-dev tooling files that hitchhiked into a PR (kitty-tmux-shim, claude-teams, dotfiles, IDE configs) and the merge strategy to use after PR review feedback is addressed. Invoke when bot reviewers (CodeRabbit, Gemini, etc.) leave comments on personal dev-environment scripts that don't belong in shipped code.
---

# conejo-kitty — PR cleanup + merge policy

Conejo (rabbit) handles bot comments. Kitty handles local-dev tooling files.

## When to invoke

When a PR has either or both of:

1. **Local-dev tooling files** committed by accident — anything that boots the developer's personal environment (terminal multiplexer wrappers, IDE configs, agent-launch scripts, dotfile fragments). Examples seen in this repo: `kitty-tmux-shim`, `claude-teams`. The tell is that bot reviewers will flag shell-script edge cases on these files.

2. **A backlog of bot comments** that have already been triaged into "apply / discuss / skip" buckets and the user is ready to land the branch.

## The two policies

### Policy A — Local-dev tooling files

**Default action: remove from the branch and add to `.gitignore`.** Do NOT patch the bot-suggested shell-script edge cases. Reasons:

- These files are personal — they boot one developer's environment. Other developers don't run them, so edge-case fixes have zero blast radius outside the original author's machine.
- Patching them invites scope creep: bots will keep flagging more edge cases on every PR.
- Leaving them in `main` is a maintenance footgun — anyone who modifies them risks breaking the original author's workflow without realizing.
- The right home is the developer's dotfiles repo (or `~/.local/bin`, where they often already live).

**Exceptions** — keep + patch only when:
- The file is documented as part of the project's contributor onboarding (e.g. listed in `CONTRIBUTING.md` as a setup script).
- Multiple developers actually use it (check `git log` for non-author commits).

If unsure, ask the user before deleting. Removal is reversible from git history but generates noise.

**How to apply:**

```bash
# 1. Remove the files
git rm <file1> <file2>

# 2. Add to .gitignore (so they can't sneak back in via `git add -A`)
# Append a section like:
#   # Local dev tooling — keep in dotfiles, not in repo
#   /kitty-tmux-shim
#   /claude-teams

# 3. Commit with a clear "remove personal dev tooling" message
# 4. Push
```

### Policy B — Merge strategy

**Default: `gh pr merge --merge` (preserve history).** Reasons:

- This repo's branches accumulate meaningful commit boundaries (per-fix commits with detailed messages). Squashing destroys the reviewable history.
- Long-lived branches like `fix_redline` keep receiving sub-PRs (e.g. `fix/burst-accept-and-drawer-counter` → `fix_redline` via #3302). Merge commits make the topology clear.
- Don't pass `--delete-branch` for long-lived integration branches (`fix_redline`, `release/*`, etc.) — only for short-lived feature branches.

**Exceptions:**
- Use `--squash` when the PR contains many WIP commits with throwaway messages and the author prefers a single clean commit on `main`.
- Use `--rebase` only when the user explicitly asks for a linear history.

**Pre-merge checklist:**
- [ ] All applied bot fixes are committed and pushed.
- [ ] tsc clean, targeted tests pass.
- [ ] Mergeable per `gh pr view`. UNSTABLE state from queued external checks (Vercel, Kilo, etc.) is acceptable when local gates are green and base is not production-critical — note it explicitly in the merge message to user.
- [ ] Confirm the base branch with the user when merging into `main` (production blast radius).

## Combined flow (how this skill executes)

```
1. List bot comments on the PR.
2. Triage into apply / discuss / skip / dev-tooling buckets.
3. Apply the safe ones; ask user about ambiguous ones.
4. For dev-tooling files: git rm + .gitignore + commit (Policy A).
5. Run gates locally (tsc + targeted tests).
6. Push.
7. Confirm base branch + merge strategy with user.
8. gh pr merge --merge (Policy B default).
```

## Naming

`conejo` (Spanish: rabbit) — for CodeRabbit and other bot reviewers whose suggestions need triage.
`kitty` — for the kitty terminal + the personal dev-tooling files (`kitty-tmux-shim`) that prompted this policy.
