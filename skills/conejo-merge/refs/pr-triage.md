# PR triage (gh CLI batch operations)

_Bulk PR cleanup that complements conejo-debug's Hunt phase and conejo-merge's shipping.
Merged from the former `pr-triage-gh` skill._

Batch-triage PRs and branches using **only `gh` CLI (incl. the `gh stack` extension) and `git`** — no browser, no manual GitHub UI.

## Stacked PRs — drive the chain with `gh stack`

Never hand-rebase each branch onto its predecessor. GitHub's stacked-PR CLI does the
whole cascade (install once, check with `gh stack --help`):

```bash
gh extension install github/gh-stack  # once
gh stack init b1 b2 b3                # adopt existing branches as one stack, bottom → top
gh stack init NEW                     # …or start a fresh stack; `gh stack add NEXT` adds a layer on top
gh stack rebase --no-trunk            # rebase every branch onto the one below it, in one cascade
gh stack rebase --continue            # after resolving a conflict
gh stack rebase --abort               # restore every branch
gh stack push                         # push all active branches
gh stack submit                       # create/update the stack's PRs
gh stack sync                         # pull remote state
gh stack view                         # show the stack
```

Plain `gh stack rebase` also pulls and rebases onto the trunk; `--no-trunk` keeps `main`
out of it. `--upstack` / `--downstack` limit the cascade to the branches above/below the
current one.

**Native-stack caveat:** PRs in a native `gh stack` stack refuse `gh pr edit --base` and
normal merge — retargeting and merging the whole stack is what `gh stack merge` is for.

## Workflow

### Phase 1 — Discovery

Fetch and list remote branches matching keywords:

```bash
git fetch origin --prune
git branch -r | grep -iE '<keyword1>|<keyword2>'
```

List matching PRs with metadata:

```bash
gh pr list --state open --limit 100 --json number,title,headRefName,state | \
  jq -r '[.[] | select(.headRefName | test("<keyword>"; "i"))] | .[] | "\(.number) | \(.state) | \(.headRefName) | \(.title)"'
```

### Phase 2 — Assessment

Inspect each PR:

```bash
gh pr view <NUMBER> --json title,author,state,additions,deletions,headRefName,mergeable,mergeStateStatus
gh pr diff <NUMBER> | head -200
gh pr view <NUMBER> --comments --json comments
```

#### Judgment Criteria

**MERGE** when:
- Critical security fix (IDOR, auth bypass, input validation)
- Root-cause fix over symptom-level band-aid (e.g., Zustand store over memoization hacks)
- Unique functionality not covered by another PR
- `mergeStateStatus` is `CLEAN` and `mergeable` is `MERGEABLE`
- Smallest clean diff when multiple PRs fix the same issue

**CLOSE** when:
- Duplicate of a merged or better PR — always leave a comment explaining which PR supersedes it
- `mergeStateStatus` is `UNSTABLE` or `UNKNOWN` and a `CLEAN` alternative exists
- Bloated diff that touches unrelated files vs a focused alternative
- Major version bumps from bots (e.g., Renovate eslint-plugin 1.x→4.x) — too risky without manual testing

**INTEGRATE (mix-and-match)** when:
- Two or more **diverged** branches/PRs each carry something worth keeping — one has the robust error handling, another the broader feature coverage, a third the security check. Do NOT just merge one and close the rest as "duplicates": cherry-pick the best of each.
- The goal is the **union of robustness + functionality + security**, not "pick a winner." Never drop a security check or an edge-case guard just to make a merge easier.

How to mix-and-match:
1. Diff each candidate against `main` AND against each other to see who has what: `gh pr diff <N>`; `git range-diff main..<branchA> main..<branchB>`.
2. For each branch, list what it does *best* across the three axes — **robustness** (error handling, edge cases, retries/timeouts, null/empty/concurrent), **functionality** (features, coverage), **security** (authz/ownership in the query, input validation, no secret/PII leakage).
3. Open an integration branch off `main`: `git checkout -b conejo/integrate-<topic> origin/main`.
4. Bring in the best pieces — `git cherry-pick <sha>` for clean self-contained commits, or hand-merge the specific hunks when they interleave. On every conflict, resolve toward the **strongest** version of each concern (the more-defensive error path, the tighter authz check), not the easiest merge.
5. Keep the tests from **all** source branches so no functionality regresses, and add a test for any seam you hand-merged.
6. Run the full suite, open the integration PR, then close each source PR with a comment pointing at it (e.g. "superseded by #<INT>, which combines the robust retry logic from #A, the feature set from #B, and the ownership check from #C").

**DELETE branch only** when:
- Stale branch with no open PR attached
- Use `git push origin --delete <branch>` (not gh)

### Phase 3 — Execution (strict order)

1. **Sync local main first:**
   ```bash
   git checkout main && git pull origin main
   ```

2. **Merge approved PRs sequentially** (one at a time, pulling between if needed):
   - **Independent PRs (all based on `main`):**
     ```bash
     gh pr merge <NUMBER> --merge --delete-branch
     ```
   - **Detect stacked PRs first.** Before merging anything, read every candidate PR's base and head:
     ```bash
     gh pr list -R <OWNER/REPO> --state open --json number,baseRefName,headRefName
     ```
     A PR is **stacked** when its `baseRefName` is another open PR's `headRefName` (not `main`/the default branch). Chain those links into bottom-up order (the one based on `main` is the bottom). If every PR's base is `main`, they're **independent** — merge them normally with `--delete-branch`. Only use the procedures below when at least one PR is stacked on another.
   - **Stack managed by `gh stack` (native stack):** its PRs refuse `gh pr edit --base` and normal `gh pr merge` — expected, not breakage. Merge the whole stack with `gh stack merge` (see the `gh stack` section above), then verify branch cleanup in step 4/5 below. Skip the manual retarget dance.
   - **Stacked PRs not managed by `gh stack` (each based on the previous branch, not `main`) — do NOT use `--delete-branch` while merging.** Deleting a branch that another open PR is *based on* orphans that PR: GitHub auto-closes it and it CANNOT be reopened against a deleted base. Instead:
     1. Retarget every still-open PR in the stack to the final base (`main`) **before** merging anything — use the REST API, because `gh pr edit --base` currently aborts on repos that still expose the deprecated projects-classic GraphQL field:
        ```bash
        gh api -X PATCH repos/<OWNER>/<REPO>/pulls/<N> -f base=main
        ```
     2. Merge bottom-up **without** `--delete-branch`:
        ```bash
        gh pr merge <N> --merge
        ```
        Re-check `mergeable` / `mergeStateStatus` between merges — a stacked PR carries the lower layers' commits until they land, then collapses to its own diff.
     3. Delete the merged branches only at the very end (step 4/5 below).
   - **Recovering an already-orphaned PR:** if a stacked PR was auto-closed when its base branch was deleted (it can't be reopened — the base is gone), recreate its content as a fresh PR to `main` and merge that. No commits are lost; the head branch still exists:
     ```bash
     gh pr create --base main --head <its-branch> --title "…" --body "Re-targeted replacement for #<CLOSED>."
     ```

3. **Close rejected/duplicate PRs** with explanatory comments:
   ```bash
   gh pr close <NUMBER> --delete-branch --comment "Closing: superseded by #<MERGED_NUMBER> which provides a cleaner fix."
   ```

4. **Delete orphan branches** (no PR):
   ```bash
   git push origin --delete <branch-name>
   ```

5. **Verify cleanup:**
   ```bash
   git fetch origin --prune
   git branch -r | grep -iE '<keyword>'
   # Should return empty
   ```

### Phase 4 — Report

Summarize what was done:
- **Merged**: list PR numbers, titles, and what they fix
- **Closed**: list PR numbers with reason (duplicate of #X, bloated, unstable)
- **Deleted**: list orphan branches removed
- **Skipped**: list anything left with rationale

## Edge Cases and Lessons

- **gh 504 timeouts**: Reduce `--limit` or request fewer `--json` fields on large repos
- **Bot-only PRs**: When all authors/reviewers are bots (Jules, Renovate, CodeRabbit, etc.), there are no human sign-offs — apply extra scrutiny to the diff yourself
- **Duplicate detection**: Compare PR titles AND diffs — two PRs can have different titles but fix the same code path
- **Post-merge conflicts**: After merging PR A, PR B targeting the same files may shift from CLEAN to UNKNOWN — re-check merge state before proceeding
- **Stacked-PR orphaning**: `--delete-branch` on a PR whose head branch is the *base* of another open PR auto-closes that dependent PR — and it can't be reopened against a deleted base. For a stack, retarget every dependent to `main` first (`gh api -X PATCH .../pulls/<N> -f base=main`), merge bottom-up **without** `--delete-branch`, and delete branches last. If the stack is `gh stack`-managed, `gh stack merge` handles the ordering for you (native stacks refuse `gh pr edit --base` and normal merge anyway — see the `gh stack` section). Recover an already-orphaned PR by recreating its content as a new PR to `main`. See Phase 3 step 2.
- **Security patterns to watch for**:
  - IDOR: `protectedProcedure` alone is insufficient; ownership must be checked in the DB query (`eq(table.userId, ctx.userId)`)
  - Substring matching: `"admin@x.com".includes("min@x.com")` is true — use `.split(",").map(s => s.trim()).includes(email)` instead
  - Lazy-loaded enums: `import type` for enums, use string literals at runtime to avoid pulling the whole library into the bundle
