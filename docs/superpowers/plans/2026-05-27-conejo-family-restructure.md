# Conejo Coding-Philosophy Family — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the monolithic `conejo` skill into a four-skill coding-philosophy family (conejo / conejo-code / conejo-frontend / conejo-merge), fold the adapted `shipshape-skills` content in, codify one universal red-green TDD doctrine (frontend = backend + extras), consolidate 13 frontend skills under `conejo-frontend/refs/`, and ship hook + sync installer scripts.

**Architecture:** Five stacked PRs in `cicero-im/conejo-skills`, each over the previous, merged with the documented stacked-merge method (retarget to `main`, no `--delete-branch` mid-stack). Skills are Markdown `SKILL.md` files with `name`/`description` frontmatter; the marketplace is `.claude-plugin/marketplace.json` (a flat `skills[]` array). Shipshape content is **adapted in** (not plugin-ported) from `/home/arthrod/workspace/muki-ai-plugins/plugins/shipshape-skills/`. The repo is canonical; a sync script mirrors to `~/.claude/skills`.

**Tech Stack:** Markdown skills, JSON marketplace, POSIX shell scripts, `jq`/`node` for JSON validation, git. Spec: `docs/superpowers/specs/2026-05-27-conejo-family-restructure-design.md`.

**Conventions:**
- Frontmatter is exactly: `---\nname: <dir-name>\ndescription: <one line>\n---`. The `name` MUST equal the skill's directory name.
- Validate marketplace.json after every edit: `node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('ok')"`.
- Shipshape source root (read-only input): `SHIP=/home/arthrod/workspace/muki-ai-plugins/plugins/shipshape-skills`.
- Work from `/home/arthrod/workspace/conejo-skills`. The branch `feat/conejo-family-restructure` already holds the spec commits; PR 1 continues on it.

---

## File structure

| Path | Responsibility |
|---|---|
| `skills/conejo-merge/SKILL.md` | All current PR-handling content (moved verbatim from `skills/conejo/`). |
| `skills/conejo/SKILL.md` | Thin philosophy + dispatcher to the other three and to existing process skills. |
| `skills/conejo-code/SKILL.md` | Active-coding loop (adapted shipshape) + links to the doctrine. |
| `skills/conejo-code/references/testing-doctrine.md` | **Canonical** universal red-green doctrine + frontend superset. |
| `skills/conejo-code/references/*.md` | Adapted shipshape feature-stages, coding-standards, etc. |
| `skills/conejo-code/hooks/*.sh` | Adapted (manual-install) hook scripts. |
| `skills/conejo-frontend/SKILL.md` | Strict frontend gate + reference index into `refs/`. |
| `skills/conejo-frontend/refs/<skill>/` | The 13 relocated frontend skills. |
| `scripts/install-conejo-hooks.sh` | Idempotent installer that merges hook entries into a settings.json. |
| `scripts/sync-to-claude.sh` | Symlink-aware mirror+safe-prune of skills to a deploy root. |
| `.claude-plugin/marketplace.json` | Registration (remove old conejo + 13 folded; add 4 conejo-*). |

---

## PR 1 — `conejo-merge` (verbatim move of current conejo)

Branch: continue on `feat/conejo-family-restructure`.

### Task 1: Move conejo → conejo-merge

**Files:**
- Move: `skills/conejo/` → `skills/conejo-merge/`
- Modify: `skills/conejo-merge/SKILL.md` (frontmatter)
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Move the directory with git**

```bash
cd /home/arthrod/workspace/conejo-skills
git mv skills/conejo skills/conejo-merge
```

- [ ] **Step 2: Update the frontmatter `name`**

Edit `skills/conejo-merge/SKILL.md` lines 1-3. Replace:
```
name: conejo
```
with:
```
name: conejo-merge
```
Leave the existing `description:` (it already describes the PR-handling modes) — it is now accurate for conejo-merge.

- [ ] **Step 3: Update marketplace registration**

In `.claude-plugin/marketplace.json`, replace the line `        "./skills/conejo",` with `        "./skills/conejo-merge",`.

- [ ] **Step 4: Verify structure**

```bash
test -f skills/conejo-merge/SKILL.md && echo "moved ok"
head -3 skills/conejo-merge/SKILL.md | grep -q "name: conejo-merge" && echo "frontmatter ok"
test ! -d skills/conejo && echo "old dir gone"
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
grep -c '"./skills/conejo"' .claude-plugin/marketplace.json   # expect 0
grep -c '"./skills/conejo-merge"' .claude-plugin/marketplace.json # expect 1
```
Expected: `moved ok`, `frontmatter ok`, `old dir gone`, `json ok`, `0`, `1`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(conejo): move PR-handling content to conejo-merge"
```

- [ ] **Step 6: Push + open PR 1**

```bash
git push -u origin feat/conejo-family-restructure
gh pr create --base main --title "refactor: conejo-merge (move PR-handling out of conejo)" \
  --body "Stacked PR 1/5. Renames the monolithic conejo skill to conejo-merge verbatim (its content is the calm/slow PR approach). Spec: docs/superpowers/specs/2026-05-27-conejo-family-restructure-design.md"
```

---

## PR 2 — `conejo` (philosophy + dispatcher)

Branch off PR 1.

### Task 2: Create the conejo philosophy skill

**Files:**
- Create: `skills/conejo/SKILL.md`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Branch**

```bash
git checkout feat/conejo-family-restructure
git checkout -b feat/conejo-philosophy
```

- [ ] **Step 2: Write `skills/conejo/SKILL.md` (full content)**

```markdown
---
name: conejo
description: arthrod's coding philosophy and dispatcher. Universal red-green TDD, stacked PRs, test-always, evidence-before-claims. Routes to conejo-code (active coding), conejo-frontend (strict UI), conejo-merge (calm PR/merge). Use when starting any coding work or deciding how to approach a task.
---

# Conejo — the coding philosophy

Conejo is how we build. It is small on purpose: it states the non-negotiables and
routes you to the focused skill for the task at hand.

## Non-negotiables

1. **Red-green TDD, always — backend and frontend alike.** Write the failing test,
   watch it fail for the right reason, write the minimum to pass, refactor under green.
   No implementation before a failing test. See [[test-driven-development]].
2. **Test always. No exceptions.** If you cannot write a test, you do not yet
   understand the problem.
3. **Stacked PRs.** Branch over branch; PR often; each PR over its predecessor.
4. **Brainstorm before building** anything non-trivial. See [[brainstorming]].
5. **Debug systematically**, never by guessing. See [[systematic-debugging]].
6. **Evidence before claims.** Never say "done/fixed/passing" without running the
   verification and showing output. See [[verification-before-completion]].

## Dispatch

| You are… | Use |
|---|---|
| Writing/changing code (logic, services, APIs, libraries, CLIs) | **[[conejo-code]]** |
| Building or changing any web UI | **[[conejo-frontend]]** (strict; it includes the conejo-code base) |
| Reviewing, interrogating, implementing, or merging PRs | **[[conejo-merge]]** |

The testing doctrine is authored once in `conejo-code/references/testing-doctrine.md`;
conejo-frontend adds the UI superset. Read the doctrine before writing any test.
```

- [ ] **Step 3: Register conejo in marketplace**

In `.claude-plugin/marketplace.json`, add `        "./skills/conejo",` immediately before `        "./skills/conejo-merge",` (keeps the array readable; order is not significant).

- [ ] **Step 4: Verify**

```bash
head -3 skills/conejo/SKILL.md | grep -q "name: conejo$" && echo "frontmatter ok"
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
grep -c '"./skills/conejo"' .claude-plugin/marketplace.json   # expect 1
```
Expected: `frontmatter ok`, `json ok`, `1`.

- [ ] **Step 5: Commit + PR**

```bash
git add -A
git commit -m "feat(conejo): philosophy + dispatcher skill"
git push -u origin feat/conejo-philosophy
gh pr create --base feat/conejo-family-restructure --title "feat: conejo philosophy/dispatcher" \
  --body "Stacked PR 2/5 (over conejo-merge). Thin philosophy umbrella routing to conejo-code/frontend/merge."
```

---

## PR 3 — `conejo-code` (active coding + canonical doctrine + hooks)

Branch off PR 2.

### Task 3: Author the canonical testing doctrine

**Files:**
- Create: `skills/conejo-code/references/testing-doctrine.md`

- [ ] **Step 1: Branch**

```bash
git checkout feat/conejo-philosophy
git checkout -b feat/conejo-code
mkdir -p skills/conejo-code/references skills/conejo-code/hooks
```

- [ ] **Step 2: Write `skills/conejo-code/references/testing-doctrine.md` (full content)**

```markdown
# Testing doctrine (canonical)

One doctrine. The red-green discipline is identical for backend and frontend;
frontend is the same base **plus** the additions in the last section. Only the
*test vehicle* differs per code kind — never the discipline.

## Universal red-green (every change: backend, frontend, CLI, library)

1. Write the failing test first. Run it. Watch it FAIL (red) for the right reason.
2. Write the minimal code to make it pass. Watch it PASS (green).
3. Refactor under green. Commit. No implementation before a failing test — no exceptions.

## Test vehicle by code kind

- **Backend / pure logic / CLI / library →** `vitest` unit/integration tests
  (transforms, Zod/schema validators, reducers, tRPC router output shape, services).
  Fast, no server.
- **Frontend UI behavior →** agent-browser E2E click-flows. The failing test is a
  user action (a click) whose expected on-screen result does not exist yet; implement
  until the click-flow goes green.

A change can need both layers (e.g. a new feature with logic + UI): write both, each red-green.

## Frontend additions (the superset — enforced by conejo-frontend)

1. Keep a dev server running 24/7; UI red-green checks run against it as agent-browser click-flows.
2. NEVER call tRPC to assert UI behavior. tRPC is allowed ONLY to obtain tokens,
   authenticate, or seed/reset state — never as a stand-in for a user action.
3. Test isolation is mandatory: each click-flow seeds/resets its own state (via the
   permitted tRPC seeding) and cleans up. No shared mutable state between flows.
4. Stack: React + Tailwind v4 + shadcn. No Ant Design. No Vue.

## Playwright → agent-browser translation (for adapted shipshape patterns)

- Code-driven selectors → agent-browser role/text clicks ("click the 'Save' button").
- Explicit `await page.waitFor…` → rely on agent-browser's built-in settling; assert on
  visible result, not on timing.
- Page objects → short reusable click-flow descriptions, not classes.
- Retries → fix the flake (isolation/seeding); do not paper over with retries.
```

- [ ] **Step 3: Verify + commit**

```bash
test -f skills/conejo-code/references/testing-doctrine.md && echo "ok"
git add skills/conejo-code/references/testing-doctrine.md
git commit -m "feat(conejo-code): canonical universal red-green testing doctrine"
```

### Task 4: Adapt shipshape into conejo-code references

**Files:**
- Create: `skills/conejo-code/references/feature-stages.md`, `coding-standards.md`, `deps-check.md`, `bug-fix-learning.md`, `auto-improve-tests.md`
- Create: `skills/conejo-code/SKILL.md`

Source (read-only): `SHIP=/home/arthrod/workspace/muki-ai-plugins/plugins/shipshape-skills`

- [ ] **Step 1: Adapt the five reference files**

For each mapping below, copy the source, then apply the **transformation rules** (identical for all): replace `npm`/`pnpm`/`yarn` → `bun`; `npm run` → `bun run`; `jest` → `vitest`; any build tool → `vite-plus` (`vp`); remove every Ant Design mention; delete Vue-specific guidance; convert any CJS (`require`/`module.exports`) to ESM; replace Playwright/code-driven E2E instructions with a one-line "see `testing-doctrine.md` (agent-browser click-flows)"; drop Figma references.

```bash
SHIP=/home/arthrod/workspace/muki-ai-plugins/plugins/shipshape-skills
D=skills/conejo-code/references
# feature-stages: concatenate the 10 stage files, dropping stage-2 (uiux-design) and
# stage-6 (uiux-review) which belong to conejo-frontend, and stage-8 (e2e) which is
# folded into the doctrine. Keep 0,1,3,4,5,7,9.
cat "$SHIP"/skills/feature-stages/stage-0-brainstorm.md \
    "$SHIP"/skills/feature-stages/stage-1-planning.md \
    "$SHIP"/skills/feature-stages/stage-3-interface.md \
    "$SHIP"/skills/feature-stages/stage-4-tests.md \
    "$SHIP"/skills/feature-stages/stage-5-implement.md \
    "$SHIP"/skills/feature-stages/stage-7-improve-tests.md \
    "$SHIP"/skills/feature-stages/stage-9-code-review.md > "$D/feature-stages.md"
cp "$SHIP"/skills/coding-standards/SKILL.md "$D/coding-standards.md"
cp "$SHIP"/skills/coding-standards/references/api-design.md "$D/coding-standards-api-design.md"
cp "$SHIP"/skills/coding-standards/references/testing.md "$D/coding-standards-testing.md"
cp "$SHIP"/skills/deps-check/SKILL.md "$D/deps-check.md"
cp "$SHIP"/skills/bug-fix-learning/SKILL.md "$D/bug-fix-learning.md"
cp "$SHIP"/skills/auto-improve-tests/SKILL.md "$D/auto-improve-tests.md"
```
Then hand-apply the transformation rules to each new file in `$D` (remove antd/Vue/Playwright/Figma/npm; point testing to `testing-doctrine.md`; for `coding-standards-testing.md`, replace its testing guidance with a pointer to `testing-doctrine.md` to avoid a second doctrine copy). Remove any source frontmatter (`---` blocks) — these are reference files, not skills.

- [ ] **Step 2: Write `skills/conejo-code/SKILL.md` (full content)**

```markdown
---
name: conejo-code
description: Active coding loop — feature stages (brainstorm→plan→interface→tests→implement→improve→review), red-green TDD execution, build-fix, deps-check, coding standards, bug-fix learning. Owns the canonical testing doctrine. Use when writing or changing code (backend, logic, APIs, libraries, CLIs).
---

# Conejo-code — active coding

The hands-on coding loop. Philosophy lives in [[conejo]]; this skill is how you execute it.

## The loop (adapted feature stages)

Brainstorm → Plan → Interface → **failing tests** → Implement → Improve tests → Code review.
Full stage notes: `references/feature-stages.md`. UI stages (design/UIUX-review) and any
visual work are owned by [[conejo-frontend]].

## Testing — READ FIRST

The universal red-green doctrine is canonical in `references/testing-doctrine.md`.
Backend/logic/CLI/library use `vitest`; UI behavior uses agent-browser click-flows
(see [[conejo-frontend]]). Never implement before a failing test.

## Standards & helpers

- Coding standards: `references/coding-standards.md` (+ `-api-design.md`).
- Dependency hygiene (bun): `references/deps-check.md`.
- Capture bug-fix learnings: `references/bug-fix-learning.md`.
- Strengthen tests after green: `references/auto-improve-tests.md`.
- Optional auto-trigger hooks: `hooks/` — install with `scripts/install-conejo-hooks.sh`.

## Tooling

bun (not npm), vitest (not jest, not `bun test`), vite-plus (`vp`) for build/check. ESM only.
```

- [ ] **Step 3: Register conejo-code in marketplace**

Add `        "./skills/conejo-code",` to the `skills` array in `.claude-plugin/marketplace.json` (e.g. immediately before `        "./skills/conejo-frontend",` does not exist yet, so place it right after the `conejo` line).

- [ ] **Step 4: Verify + commit**

```bash
head -3 skills/conejo-code/SKILL.md | grep -q "name: conejo-code$" && echo "fm ok"
! grep -Rqi "ant design\|playwright\|\bvue\b\|npm install" skills/conejo-code/references && echo "no forbidden refs"
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
grep -c '"./skills/conejo-code"' .claude-plugin/marketplace.json   # expect 1
git add skills/conejo-code .claude-plugin/marketplace.json
git commit -m "feat(conejo-code): active-coding loop + adapted shipshape references"
```
Expected: `fm ok`, `no forbidden refs`, `json ok`, `1`.

### Task 5: Hooks + installer script

**Files:**
- Create: `skills/conejo-code/hooks/pre-edit-cookbook-check.sh`, `post-stop-bug-fix-learning.sh`
- Create: `scripts/install-conejo-hooks.sh`

- [ ] **Step 1: Adapt the two hook scripts**

```bash
SHIP=/home/arthrod/workspace/muki-ai-plugins/plugins/shipshape-skills
cp "$SHIP"/hooks/pre-edit-cookbook-check.sh skills/conejo-code/hooks/
cp "$SHIP"/hooks/post-stop-bug-fix-learning.sh skills/conejo-code/hooks/
chmod +x skills/conejo-code/hooks/*.sh
```
Hand-edit each to remove any shipshape-specific paths and to reference `conejo-code`
conventions; keep them dependency-free POSIX `sh`.

- [ ] **Step 2: Write the failing test (dry-run contract)**

Create `scripts/install-conejo-hooks.sh` will be tested by its own `--dry-run`. First write the expected behavior as a check script `scripts/_test-install-hooks.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d)
echo '{}' > "$tmp/settings.json"
# dry-run must NOT modify the file and must print the planned hook keys
out=$(bash scripts/install-conejo-hooks.sh --settings "$tmp/settings.json" --dry-run)
grep -q "PreToolUse" <<<"$out" || { echo "FAIL: dry-run did not mention PreToolUse"; exit 1; }
grep -q "Stop" <<<"$out" || { echo "FAIL: dry-run did not mention Stop"; exit 1; }
[ "$(cat "$tmp/settings.json")" = '{}' ] || { echo "FAIL: dry-run modified settings"; exit 1; }
# real run must add hooks and be idempotent
bash scripts/install-conejo-hooks.sh --settings "$tmp/settings.json" >/dev/null
node -e "const s=require('$tmp/settings.json');if(!s.hooks)process.exit(1);console.log('hooks added')"
bash scripts/install-conejo-hooks.sh --settings "$tmp/settings.json" >/dev/null
cnt=$(node -e "const s=require('$tmp/settings.json');console.log(JSON.stringify(s.hooks).split('post-stop-bug-fix-learning').length-1)")
[ "$cnt" = "1" ] || { echo "FAIL: not idempotent (count=$cnt)"; exit 1; }
echo "ALL PASS"; rm -rf "$tmp"
```

- [ ] **Step 3: Run the test — verify it FAILS**

```bash
chmod +x scripts/_test-install-hooks.sh
bash scripts/_test-install-hooks.sh || echo "expected failure: installer not written yet"
```
Expected: failure (script `scripts/install-conejo-hooks.sh` does not exist).

- [ ] **Step 4: Write `scripts/install-conejo-hooks.sh` (full content)**

```bash
#!/usr/bin/env bash
# Idempotently merge conejo-code's hooks into a Claude Code settings.json.
# Usage: install-conejo-hooks.sh [--settings <path>] [--dry-run]
set -euo pipefail
SETTINGS="${HOME}/.claude/settings.json"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --settings) SETTINGS="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills/conejo-code/hooks"
PRE="$HOOK_DIR/pre-edit-cookbook-check.sh"
POST="$HOOK_DIR/post-stop-bug-fix-learning.sh"

if [ "$DRY" = "1" ]; then
  echo "Would add to $SETTINGS:"
  echo "  PreToolUse(Edit|Write) -> $PRE"
  echo "  Stop -> $POST"
  exit 0
fi

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
node - "$SETTINGS" "$PRE" "$POST" <<'NODE'
const fs = require('fs');
const [file, pre, post] = process.argv.slice(2);
const s = JSON.parse(fs.readFileSync(file, 'utf8'));
s.hooks = s.hooks || {};
const ensure = (event, matcher, cmd) => {
  s.hooks[event] = s.hooks[event] || [];
  const exists = JSON.stringify(s.hooks[event]).includes(cmd);
  if (!exists) s.hooks[event].push({ matcher, hooks: [{ type: 'command', command: cmd }] });
};
ensure('PreToolUse', 'Edit|Write', pre);
ensure('Stop', '', post);
fs.writeFileSync(file, JSON.stringify(s, null, 2) + '\n');
console.log('conejo hooks installed in ' + file);
NODE
```

- [ ] **Step 5: Run the test — verify it PASSES**

```bash
chmod +x scripts/install-conejo-hooks.sh
bash scripts/_test-install-hooks.sh
```
Expected: `ALL PASS`.

- [ ] **Step 6: Remove the throwaway test, commit**

```bash
rm scripts/_test-install-hooks.sh
git add skills/conejo-code/hooks scripts/install-conejo-hooks.sh
git commit -m "feat(conejo-code): adapted hooks + idempotent install-conejo-hooks.sh"
git push -u origin feat/conejo-code
gh pr create --base feat/conejo-philosophy --title "feat: conejo-code + doctrine + hooks" \
  --body "Stacked PR 3/5 (over conejo philosophy). Active-coding skill, canonical testing doctrine, adapted shipshape references, manual hook installer."
```

---

## PR 4 — `conejo-frontend` + fold (with loader pilot)

Branch off PR 3.

### Task 6: Create conejo-frontend and pilot-fold one skill

**Files:**
- Create: `skills/conejo-frontend/SKILL.md`
- Move: `skills/seo-audit/` → `skills/conejo-frontend/refs/seo-audit/`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Branch + scaffold**

```bash
git checkout feat/conejo-code
git checkout -b feat/conejo-frontend
mkdir -p skills/conejo-frontend/refs
```

- [ ] **Step 2: Write `skills/conejo-frontend/SKILL.md` (full content)**

```markdown
---
name: conejo-frontend
description: VERY STRICT frontend gate. Enforces the universal red-green doctrine PLUS the UI superset — agent-browser E2E click-flows (NEVER tRPC to assert UI), 24/7 dev server, test isolation, React + Tailwind v4 + shadcn (NO Ant Design). Indexes the design/UI reference skills. Use for any web UI work.
---

# Conejo-frontend — the strict UI gate

Frontend is [[conejo-code]] + the additions below. The red-green discipline is the same;
the vehicle for UI behavior is agent-browser click-flows. Doctrine is canonical in
`../conejo-code/references/testing-doctrine.md` — read it first.

## Hard rules (refuse work that violates these)

1. **Red-green, always.** No UI implementation before a failing agent-browser click-flow.
2. **NEVER use tRPC to assert UI behavior.** tRPC only for tokens/auth/seeding state.
3. **Dev server runs 24/7;** UI checks click against it via agent-browser (see [[browser-test-agent]]).
4. **Test isolation:** each click-flow seeds/resets its own state and cleans up.
5. **Stack:** React + Tailwind v4 + shadcn. **No Ant Design. No Vue.**
6. Consult the relevant reference below before accepting frontend work as done.

## Reference index (folded skills under `refs/`)

- **Design taste & critique:** `refs/refine-distill-frontend`, `refs/ui-ux-pro-max`, `refs/increase-impact-personality-frontend`, `refs/stitch-design-taste`
- **Typography:** `refs/typeset`, `refs/type-mania`
- **Color:** `refs/colorize`
- **UX planning:** `refs/ux-design-brief`
- **shadcn parity:** `refs/shadcn-parity`
- **Routing:** `refs/tanstack-router`, `refs/tanstack-router-best-practices`
- **Generative UI:** `refs/json-render`
- **SEO:** `refs/seo-audit`

Foundational React/styling/layout skills stay top-level: [[react]], [[react-best-practices]],
[[react-composables]], [[tailwind-v4]], [[layout]].
```

- [ ] **Step 3: Pilot-fold `seo-audit` and verify loader resolution**

```bash
git mv skills/seo-audit skills/conejo-frontend/refs/seo-audit
# deregister seo-audit from marketplace
# (remove the line '        "./skills/seo-audit",' from .claude-plugin/marketplace.json)
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
test -f skills/conejo-frontend/refs/seo-audit/SKILL.md && echo "pilot moved ok"
grep -c '"./skills/seo-audit"' .claude-plugin/marketplace.json   # expect 0
```
Remove `        "./skills/seo-audit",` from `.claude-plugin/marketplace.json` (the Edit), then re-run the checks. Expected: `json ok`, `pilot moved ok`, `0`.

- [ ] **Step 4: Register conejo-frontend + commit the pilot**

Add `        "./skills/conejo-frontend",` to the marketplace `skills` array.
```bash
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
git add -A
git commit -m "feat(conejo-frontend): strict UI skill + pilot-fold seo-audit"
```
**Checkpoint (per spec I3):** confirm with the user/Claude that `refs/seo-audit` still resolves when referenced (skills are addressed by registered path/name; `refs/` skills are intentionally NOT registered — they are reference docs reached via conejo-frontend's index, not standalone skills). If resolution requires registration, STOP and switch to "reference-only" (leave dirs top-level, just deregister) before Task 7.

### Task 7: Bulk-fold the remaining 12 + migrate cross-refs

**Files:**
- Move 12 dirs into `skills/conejo-frontend/refs/`
- Modify: `skills/adapt/SKILL.md`, `skills/impeccable/SKILL.md` (cross-ref paths)
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Move the 12 remaining skills**

```bash
for s in refine-distill-frontend increase-impact-personality-frontend ui-ux-pro-max \
         stitch-design-taste colorize typeset type-mania ux-design-brief \
         shadcn-parity json-render tanstack-router tanstack-router-best-practices; do
  git mv "skills/$s" "skills/conejo-frontend/refs/$s"
done
```

- [ ] **Step 2: Deregister all 12 from marketplace**

Remove these 12 lines from the `skills` array in `.claude-plugin/marketplace.json`:
`"./skills/refine-distill-frontend"`, `"./skills/increase-impact-personality-frontend"`, `"./skills/ui-ux-pro-max"`, `"./skills/stitch-design-taste"`, `"./skills/colorize"`, `"./skills/typeset"`, `"./skills/type-mania"`, `"./skills/ux-design-brief"`, `"./skills/shadcn-parity"`, `"./skills/json-render"`, `"./skills/tanstack-router"`, `"./skills/tanstack-router-best-practices"`.

- [ ] **Step 3: Migrate the inbound cross-refs in `adapt` and `impeccable`**

The audit found only `adapt` and `impeccable` reference any folded skill (the six: `ui-ux-pro-max`, `stitch-design-taste`, `colorize`, `typeset`, `ux-design-brief`, `shadcn-parity`). In `skills/adapt/SKILL.md` and `skills/impeccable/SKILL.md`, rewrite any `[[<skill>]]` / `skills/<skill>` reference to those six to point at conejo-frontend (e.g. `[[conejo-frontend]] (refs/<skill>)`), since they are no longer standalone skills.

```bash
# find the exact references to update
grep -nE "ui-ux-pro-max|stitch-design-taste|colorize|typeset|ux-design-brief|shadcn-parity" \
  skills/adapt/SKILL.md skills/impeccable/SKILL.md
```
Edit each hit to the conejo-frontend form. Re-run the grep; every remaining hit must be inside a deliberate "see conejo-frontend" sentence.

- [ ] **Step 4: Verify no stale references remain anywhere**

```bash
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
# no marketplace entry should point at a moved skill
for s in refine-distill-frontend increase-impact-personality-frontend ui-ux-pro-max \
         stitch-design-taste colorize typeset type-mania ux-design-brief \
         shadcn-parity json-render tanstack-router tanstack-router-best-practices seo-audit; do
  grep -q "\"./skills/$s\"" .claude-plugin/marketplace.json && echo "STALE REG: $s"
  test -d "skills/$s" && echo "STILL TOP-LEVEL: $s"
  test -d "skills/conejo-frontend/refs/$s" || echo "MISSING IN REFS: $s"
done
echo "checks done"
```
Expected: no `STALE REG`, no `STILL TOP-LEVEL`, no `MISSING IN REFS` lines; `json ok`, `checks done`.

- [ ] **Step 5: Confirm foundational skills stayed**

```bash
for s in react react-best-practices react-composables layout tailwind-v4 impeccable dogfood dogfood-quirks browser-test-agent i18n-inlang-localization; do
  test -d "skills/$s" && grep -q "\"./skills/$s\"" .claude-plugin/marketplace.json || echo "PROBLEM: $s missing/unregistered"
done
echo "foundational ok"
```
Expected: no `PROBLEM` lines; `foundational ok`.

- [ ] **Step 6: Commit + PR**

```bash
git add -A
git commit -m "feat(conejo-frontend): fold 13 design/UI skills into refs/, migrate adapt+impeccable refs"
git push -u origin feat/conejo-frontend
gh pr create --base feat/conejo-code --title "feat: conejo-frontend + fold 13 FE skills" \
  --body "Stacked PR 4/5 (over conejo-code). Strict FE gate; relocates 13 design/UI skills to refs/ and deregisters them; keeps react/layout/tailwind foundational; migrates the only inbound refs (adapt, impeccable)."
```

---

## PR 5 — sync script + docs + marketplace metadata

Branch off PR 4.

### Task 8: sync-to-claude.sh (safe mirror+prune)

**Files:**
- Create: `scripts/sync-to-claude.sh`

- [ ] **Step 1: Branch**

```bash
git checkout feat/conejo-frontend
git checkout -b feat/conejo-sync-docs
```

- [ ] **Step 2: Write the failing test**

Create `scripts/_test-sync.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
root=$(mktemp -d)/skills; mkdir -p "$root"
# a folded skill currently deployed as a real dir with a local modification
mkdir -p "$root/colorize"; echo "LOCAL EDIT" > "$root/colorize/SKILL.md"
# dry-run must report the plan and NOT delete the locally-modified dir
out=$(bash scripts/sync-to-claude.sh --root "$root" --dry-run)
grep -q "conejo-frontend" <<<"$out" || { echo "FAIL: no mirror plan"; exit 1; }
test -f "$root/colorize/SKILL.md" || { echo "FAIL: dry-run deleted files"; exit 1; }
# real run must WARN and refuse to prune the modified dir
out=$(bash scripts/sync-to-claude.sh --root "$root" 2>&1 || true)
grep -qi "warn\|refus\|skip" <<<"$out" || { echo "FAIL: did not warn on local mod"; exit 1; }
test -f "$root/colorize/SKILL.md" || { echo "FAIL: pruned a locally-modified dir"; exit 1; }
# conejo-frontend should now be mirrored
test -f "$root/conejo-frontend/SKILL.md" || { echo "FAIL: did not mirror conejo-frontend"; exit 1; }
echo "ALL PASS"
```

- [ ] **Step 3: Run — verify FAIL**

```bash
chmod +x scripts/_test-sync.sh
bash scripts/_test-sync.sh || echo "expected fail: sync not written"
```
Expected: failure (script missing).

- [ ] **Step 4: Write `scripts/sync-to-claude.sh` (full content)**

```bash
#!/usr/bin/env bash
# Mirror the four conejo-* skills to a deploy root and prune the 13 folded skills.
# Symlink-aware; refuses to delete locally-modified real directories.
# Usage: sync-to-claude.sh [--root <dir>] [--dry-run]
set -euo pipefail
ROOT="${HOME}/.claude/skills"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MIRROR="conejo conejo-code conejo-frontend conejo-merge"
PRUNE="refine-distill-frontend increase-impact-personality-frontend ui-ux-pro-max \
stitch-design-taste colorize typeset type-mania ux-design-brief shadcn-parity \
json-render tanstack-router tanstack-router-best-practices seo-audit"

for s in $MIRROR; do
  echo "mirror: $s -> $ROOT/$s"
  [ "$DRY" = "1" ] && continue
  rm -rf "$ROOT/$s"; mkdir -p "$ROOT/$s"
  cp -R "$REPO/skills/$s/." "$ROOT/$s/"
done

for s in $PRUNE; do
  t="$ROOT/$s"
  [ -e "$t" ] || continue
  if [ -L "$t" ]; then
    echo "prune symlink: $t"
    [ "$DRY" = "1" ] || rm -f "$t"
  elif [ -d "$t" ]; then
    if diff -rq "$t" "$REPO/skills/conejo-frontend/refs/$s" >/dev/null 2>&1; then
      echo "prune clean copy: $t"
      [ "$DRY" = "1" ] || rm -rf "$t"
    else
      echo "WARN: refusing to prune locally-modified $t (resolve manually)"
    fi
  fi
done
echo "sync complete${DRY:+ (dry-run)}"
```

- [ ] **Step 5: Run — verify PASS, then clean up**

```bash
chmod +x scripts/sync-to-claude.sh
bash scripts/_test-sync.sh
rm scripts/_test-sync.sh
```
Expected: `ALL PASS`.

- [ ] **Step 6: Commit**

```bash
git add scripts/sync-to-claude.sh
git commit -m "feat(scripts): symlink-aware sync-to-claude with safe prune"
```

### Task 9: README family map + marketplace metadata

**Files:**
- Modify: `README.md`
- Modify: `.claude-plugin/marketplace.json` (metadata description + version + bundle description)

- [ ] **Step 1: Update marketplace metadata**

In `.claude-plugin/marketplace.json`: bump `metadata.version` `"2.0.0"` → `"3.0.0"`; update `metadata.description` and the bundle `description` ("All 94 skills…") to reflect the conejo family and the new count (85). Verify count:
```bash
node -e "const m=require('./.claude-plugin/marketplace.json');console.log('registered:', m.plugins[0].skills.length)"
```
Expected: `registered: 85` (95 start − conejo + conejo-merge + conejo + conejo-code + conejo-frontend − 13 folded).

- [ ] **Step 2: Update README family map**

In `README.md`, add a "Conejo family" section: `conejo` (philosophy/dispatcher) → `conejo-code` (active coding + doctrine) → `conejo-frontend` (strict UI; folds 13 design/UI skills under `refs/`) → `conejo-merge` (calm PR/merge). Note that `react`/`react-best-practices`/`react-composables`/`layout`/`tailwind-v4` remain foundational top-level skills, and document `scripts/install-conejo-hooks.sh` and `scripts/sync-to-claude.sh`.

- [ ] **Step 3: Verify + commit + PR**

```bash
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'));console.log('json ok')"
git add README.md .claude-plugin/marketplace.json
git commit -m "docs: conejo family map + marketplace v3.0.0 (84 skills)"
git push -u origin feat/conejo-sync-docs
gh pr create --base feat/conejo-frontend --title "docs+scripts: sync, README family map, marketplace v3" \
  --body "Stacked PR 5/5 (over conejo-frontend). sync-to-claude.sh, README family map, marketplace metadata/version/count."
```

### Task 10: Deploy + final verification

- [ ] **Step 1: Dry-run then run the sync**

```bash
bash scripts/sync-to-claude.sh --dry-run
bash scripts/sync-to-claude.sh
```
Expected: the four conejo-* skills mirrored to `~/.claude/skills`; the 13 folded names pruned (or WARN if locally modified).

- [ ] **Step 2: Confirm the family loads and folded names are gone from top level**

```bash
for s in conejo conejo-code conejo-frontend conejo-merge; do test -f "$HOME/.claude/skills/$s/SKILL.md" && echo "live: $s"; done
for s in colorize typeset json-render seo-audit; do test -e "$HOME/.claude/skills/$s" && echo "STILL PRESENT: $s"; done
echo "done"
```
Expected: four `live:` lines; no `STILL PRESENT` lines.

---

## Self-review notes

- **Spec coverage:** four-skill split (Tasks 1,2,4,6) ✓; universal red-green doctrine + frontend superset (Task 3 `testing-doctrine.md`) ✓; C2 unit-test carve-out (doctrine "test vehicle by code kind") ✓; C1 keep react/layout/tailwind foundational (Task 7 Step 5) ✓; relocate+dereference 13 (Tasks 6-7) ✓; I3 loader pilot (Task 6 Step 3 + checkpoint) ✓; I4 cross-ref migration of adapt+impeccable (Task 7 Step 3) ✓; I5 safe-prune (Task 8 test + script) ✓; hook installer (Task 5) ✓; marketplace 84 + version (Task 9) ✓; sync (Tasks 8,10) ✓; shipshape adapt drop antd/Vue/Playwright/Figma, bun/vitest/ESM (Task 4) ✓.
- **Placeholders:** scripts and SKILL.md files are given in full; shipshape reference files are adaptations of named source files with explicit transformation rules (the source is the input, not a placeholder).
- **Type/name consistency:** skill `name:` always equals its dir; the 13 folded names are identical across Tasks 6-10 and the sync script's `PRUNE` list. Marketplace count: start 95 → PR1 conejo→conejo-merge (net 0, 95) → PR2 +conejo (96) → PR3 +conejo-code (97) → PR4 +conejo-frontend −13 folded (85). Authoritative assertion in Task 9 Step 1 = **85**.
- **Out of scope:** internal refactor of conejo-merge's 1035 lines (spec M6).
