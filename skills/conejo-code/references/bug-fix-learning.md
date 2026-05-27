
# Bug Fix Learning — Disciplined Repair and Knowledge Consolidation

## When to Trigger

Trigger automatically for **any technical problem**, not only when the user explicitly reports one:

### User-described problems

- "Found a bug", "there's an error here", "this is broken", "wrong", "did it wrong", "wrote it wrong"
- "Why isn't XXX there?", "XXX isn't showing up", "XXX doesn't work"
- "Why is this happening?", "it should be X but it's Y", "something looks off here"
- Any description where the code's actual behaviour doesn't match the expected behaviour

### Context-triggered (no explicit report needed)

- **Test failure** — running tests produces red output or an assertion error
- **Build failure** — compile error, bundler error
- **Unexpected behaviour** — the feature runs but produces the wrong result
- **Performance problem** — noticeable performance regression or freeze
- **Integration problem** — an error that appears only when multiple components interact
- **A previous fix didn't work** — the problem was attempted once but didn't go away, or fixing A broke B

### GitHub issue triage

When the user says "look at this issue", "handle issue #123", or "this ticket", first read the issue with `gh issue view`, then classify it:

| Issue type | Trigger? |
|------------|----------|
| Bug / defect / regression / "broken, wrong, not working" | Yes — must trigger, run the full flow |
| Feature request / enhancement | No — use the `/feature` flow instead |
| Question / usage question | No |
| Documentation | No |
| Refactor / chore | No (unless a bug is also being fixed) |

Classification criteria: issue label, title keywords (`bug`, `fix`, `broken`, `not working`, `crash`, `error`, `regression`), and whether the body describes "actual behaviour vs expected behaviour". When in doubt, read the body — labels are often missing or incorrect.

### Do not trigger

- Pure typo or spelling mistake (just fix it)
- Simple import path error (the IDE / tsc will point it out)
- Config file formatting error (just correct it)
- A feature that is intentionally incomplete and still in development

## Execution Flow

### Step 1: Disciplined Repair

> **Iron Law: do not start changing code until the root cause has been found.**
> Speculative fixes waste time and create new bugs.

#### 1a. Root-cause investigation

**Before touching any code**, work through these steps in order:

1. **Read the full error message** — do not skip the error message, stack trace, or warnings. They usually point directly to the answer. Note the line number, file path, and error code.
2. **Achieve stable reproduction** — can it be triggered every time? What are the exact steps? If it can't be reproduced, gather more data first; do not guess.
3. **Check recent changes** — `git diff`, recent commits, newly installed dependencies, changed config.
4. **Trace the data flow** — where does the bad value come from? Who passed it in? Trace it all the way back to the source. **Fix it at the source, not at the symptom.**

**Extra steps for multi-component systems:** If the system has multiple layers (API → Service → DB, CI → Build → Deploy), add logging at each component boundary to confirm **which layer is broken** before diving deeper into that layer.

**Fast path:** If the error message directly identifies the root cause (e.g. an explicit null reference, a type error, a missing import), note the root cause and jump straight to 1d, skipping 1b/1c.

#### 1b. Pattern analysis

- Find code in the codebase that is **similar but working correctly**
- Compare the broken code with the working code and note every difference
- Assume no difference is irrelevant until proven otherwise

#### 1c. Hypothesis and minimal validation

- State a clear hypothesis: "I believe the root cause is X, because Y"
- Make the **smallest possible change** to test the hypothesis — change one variable at a time
- If validation fails, form a new hypothesis — **do not stack more fixes on top of a failed fix**

#### 1d. Implement the fix

- Fix the root cause, not the symptom
- Make one fix at a time; do not refactor at the same time
- Run the tests after fixing to confirm

**Three-failure rule:** If three separate fix attempts have all failed to resolve the problem, **stop and question the architecture**:
- Is the pattern itself flawed?
- Is the problem being solved in the wrong way?
- Raise an architectural discussion with the user; do not attempt a fourth fix.

#### 1e. Root-cause record

After the fix is complete, record the conclusions of the root-cause analysis (used in Step 2 to evaluate whether to consolidate):
- **What went wrong?** (the specific incorrect behaviour)
- **Why did it go wrong?** (the underlying cause)
- **Is this error generalizable?** (could other developers, or a future AI, make the same mistake?)

### Step 2: Evaluate Whether to Consolidate

The cookbook's full purpose and the three-question test are covered in CLAUDE.md under "Quality Gates → Cookbook Sync". The summary applicable to this skill is below.

The cookbook only collects knowledge that is **invisible to code, types, tests, and import relationships**. Things that mechanical tools can catch should not be written down, because those things rot as the code evolves while the mechanical tools do not.

**Three-question test before writing** (answer "yes" to any one → do not write):

1. **Would tsc / eslint catch it?** — e.g. "changing a signature requires updating all call sites". Yes → don't write; the types are already the documentation.
2. **Would grep import or deps-check reveal the relationship?** — e.g. "changing noteService requires updating NoteList". Yes → don't write; rely on dependency checking.
3. **Would a test fail?** — e.g. "listNotes should return a sorted array". Yes → don't write; the test is the contract.

**The only things worth writing to the cookbook:**

**A. Bugs and technical pitfalls**
- **Hidden cross-timing / cross-runtime coupling**: event ordering, debounce, race conditions
- **External library traps**: a Plate.js function crashes on special characters; a Firebase API behaves differently in Electron
- **Hidden data contracts**: the UI must stay in sync with a constants list but there is no type link

**B. Business logic**
- **Business rules that the code cannot explain**: a sensor displays `--` after 30 minutes offline (the business defined this, it is not a technical constraint)
- **Domain-specific calculations**: yield rate formula, report data aggregation rules
- **Process constraints**: one API must be called after another; a state transition has a precondition

**C. Architectural decisions**
- **The "why" behind historical decisions**: why Y was used here instead of X (without documenting this, the decision gets relitigated endlessly)
- **Technology selection rationale**: why date-fns instead of dayjs; why a component doesn't use a third-party library
- **Design rules that are hard to automate**: dark-mode colour pairings, brand colour usage (these often belong in CLAUDE.md instead)

**Reference table:**

| Content | Write to cookbook? | Why |
|---|---|---|
| noteService.listNotes returns a Promise | No | Already expressed by the type |
| Changing noteService requires changing NoteList | No | deps-check can find this |
| render_widget retry overwrites agentStorage, needs debounce | Yes | Timing coupling — tsc cannot catch it |
| Plate.js markdownToSlateNodes crashes on `$` | Yes | External library trap |
| OFFICIAL_NOTE_TYPES must stay in sync with the UI menu | Yes | Hidden data contract |
| Sensor displays `--` after 30 minutes offline | Yes | Business rule — the code doesn't explain why 30 minutes |
| Yield rate excludes the first 10 minutes of warm-up data | Yes | Domain knowledge — without it the calculation will be wrong |
| Using date-fns instead of dayjs because tree-shaking is better | Yes | Architectural decision — without it the choice will keep being questioned |
| This bug was fixed in 3 lines | No | Already in git log |
| The Button component lives in src/components/ui/ | No | grep finds it; writing it down will rot |

**Important: the three-question test is not a veto, it is a router.** Answering "yes" means the knowledge should be guarded by a mechanical tool, not put in the cookbook. Step 4 must tell the user where the knowledge should go (add a type, add a lint rule, add a test, or write to the cookbook) — not just say "don't write" and stop.

Output your evaluation result:

```
Consolidation evaluation:
- Cookbook: ✅ needs to be written (reason: ...) / ❌ not needed (reason: ...)
- Memory:   ✅ needs to be written (reason: ...) / ❌ not needed (reason: ...)
- Workflow: ✅ needs to be written (reason: ...) / ❌ not needed (reason: ...)
```

Reference table for consolidation targets:

| Target | When to write | Example |
|--------|---------------|---------|
| **Cookbook** (`docs/cookbook/`) | Project-specific patterns, API usage, component pitfalls, errors likely to recur | Dashboard error handling must wrap ErrorBoundary |
| **Memory** (feedback type) | Cross-project general development feedback | User's preferred confirmation granularity |
| **Workflow** (`.claude/commands/`) | Errors caused by a process gap | Stage 5 was missing a mandatory completeness check |

Multiple targets can be written simultaneously. **Critical: once you mark ✅ in the evaluation, Step 3 must complete the corresponding write action. The evaluation is for deciding whether to write — finishing the evaluation is not the finish line.**

### Step 3: Write to Files

This is the action step. Your job here is to call the Edit or Write tool and put the root-cause analysis from Step 1e into the appropriate file. If you finish Step 3 without having called any write tool, you missed something.

#### 3a. Write to Cookbook

1. Use Glob to search `docs/cookbook/**/*.md`; find the folder and file matching the module you changed
2. Write business logic to `docs/cookbook/<module>/business-rules.md`, pitfall records to `docs/cookbook/<module>/pitfalls.md`, architectural decisions to `docs/cookbook/architecture/`
3. Use Read to open the file, then Edit to append the record. If the folder or file doesn't exist, create it with Bash + Write

**Format example for written content:**

```markdown
### Error handling must wrap ErrorBoundary

**Problem**: Dashboard module calls the API directly in the render without error handling — uncaught errors cause the whole page to white-screen.

**Root cause**: Each module loads data independently but has no individual error boundary, so one module's API error causes the entire Dashboard to unmount.

✅ Correct:
```tsx
<ErrorBoundary>
  <SensorModule config={config} />
</ErrorBoundary>
```

❌ Wrong:
```tsx
<SensorModule config={config} />
```
```

#### 3b. Write to Memory (if Step 2 marked ✅)

1. Create a `feedback_*.md` file in the memory directory
2. Include **Why** (why the mistake was made) and **How to apply** (how to avoid it in the future)
3. Update the `MEMORY.md` index

#### 3c. Update Workflow (if Step 2 marked ✅)

1. Add a check item to the relevant command (e.g. `feature.md`)
2. Explain at which stage this type of error should be intercepted

### Step 4: Unconditionally Output the Evaluation Summary

**This is a mandatory step and cannot be skipped.** Regardless of whether Step 2 decided to write anything, always output the format below so the user can see the skill ran the complete flow. Silent completion = the user assumes the skill didn't trigger, which is exactly the failure mode this skill is meant to prevent.

**Case A: Something was written** (list the files actually modified)

```
Bug learning recorded:
- Cookbook: docs/cookbook/xxx.md (added ErrorBoundary note)
- Memory:   no update needed
- Workflow: no update needed
```

**Case B: Nothing needed to be written** (explain why, and suggest an alternative action)

```
Bug learning evaluation:
- Cookbook: not written (reason: this is a type contract — tsc already enforces it)
- Memory:   not written (reason: project-specific, not appropriate for cross-project feedback)
- Workflow: not written
- Suggested alternative: add a return type annotation to `listNotes()` — tsc will then block callers with mismatched types directly
```

"Suggested alternative action" is the core of Step 4 — if the cookbook is not written, always tell the user what should be done instead. Options include:

- Add a type / type guard (tsc can catch it)
- Add an eslint rule (lint can catch it)
- Add a unit test / end-to-end test (tests can catch it)
- Remind the user to run deps-check to confirm all dependents have been reviewed
- No action needed at all (e.g. a pure typo or a one-off environment error)

Only write to the cookbook when "none of the above applies" **and** "the mistake is likely to recur".

## When Not to Consolidate

**Default is not to write.** Only knowledge that passes the three-question test in Step 2 — hidden knowledge that mechanical tools cannot catch — should go into the cookbook. Common cases that do not warrant writing:

- Pure typo, environment problem, one-off config error
- Errors that tsc / eslint / tests / deps-check can catch (fix the code or add the test instead)
- The cookbook already has the same record (in this case, investigate why it wasn't caught — is the rule unclear, or is nobody reading it?)
- Pure implementation details (e.g. "changing this loop to for...of is faster" — fix the code; no need to document it)

Too many entries cause the cookbook to rot and stop being read. Err on the side of less.
