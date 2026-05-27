
# Stage 0: Requirements Clarification (Socratic Questioning)

Before planning, clarify requirements through focused questions:

- **Ask one question at a time** — no rapid-fire lists
- **Prefer multiple-choice over open-ended** (e.g. "A or B?" not "What do you want?")
- Explore **2-3 different approaches**, explaining trade-offs for each
- Confirm design decisions incrementally: "Does this look right?"
- Apply **YAGNI actively**: cut unnecessary scope during the design phase

> Skip condition: requirements are already extremely specific (e.g. "add Z logic to function Y in file X").

No pause needed after this stage — proceed directly to Stage 1 once requirements are clear.

---

# Stage 1: Planning

## Pre-knowledge Check (Mandatory)

Before exploring code, **always** consult existing knowledge to avoid repeating mistakes or violating established architecture:

1. **Cookbook cross-reference (progressive disclosure)**: Read `docs/cookbook/README.md` → find relevant module folder → read `MOC.md` → read relevant `business-rules.md` (domain logic) and `pitfalls.md` (known traps). Also check `architecture/MOC.md` for related architectural decisions.
2. **Memory feedback**: Read feedback records in memory to check for past experience relevant to this development task.

Pass the knowledge found to the planner subagent so planning can account for known business rules, pitfalls, and architectural constraints.

## Execute Planning

Use the Agent tool to dispatch a **planner** subagent (`subagent_type: "shipshape-skills:planner"`). Pass in: the user's requirement description, relevant file paths, project tech stack, **and the cookbook/memory content from the pre-knowledge check**.

The planner subagent is responsible for:
- Clarifying requirements and edge conditions
- Identifying files to modify/create
- Evaluating risks and dependencies
- Producing an implementation plan where **every step must be specific: file path, function name, expected behavior** (assume the executor knows nothing about the project)
- **Determining whether this feature involves UI changes** (if yes, proceed to Stage 2; if not, skip Stage 2 and go directly to Stage 3)

## Skip Suggestions (Mandatory)

After producing the implementation plan, **must** also provide skip suggestions:

1. List all stages (0–9)
2. Mark each as `recommended` or `skip`, with reasoning
3. Wait for user confirmation of which stages to execute and which to skip

Decision criteria:

| Condition | Stages that can be skipped |
|-----------|---------------------------|
| No UI changes | Stage 2 (UI/UX Design), Stage 6 (UIUX Review) |
| ≤2 files changed, logic is clear | Stage 3 (Interface Design) |
| Pure UI adjustment (no business logic) | Stage 4 (Unit Tests), Stage 7 (Improve Tests) |
| Small change scope, manually verifiable | Stage 8 (E2E Tests) |

**Stages that must never be skipped**: Stage 1 (Planning), Stage 5 (Implementation), Stage 9 (Code Review).

## Plan Quality Check (No Placeholders)

After producing the plan, self-check for the following forbidden patterns. Rewrite any step that contains one:

**Forbidden phrasing**:
- "TBD", "to be determined", "decide later"
- "add appropriate error handling", "add necessary validation"
- "adjust according to requirements", "depending on the situation"
- "implement following existing patterns" (without specifying which pattern and which file)
- "similar to XXX approach" (without attaching a concrete code path)

**Every step must include**:
- Concrete file path (not just "in the service layer")
- Concrete function name or component name
- Expected input/output or behavior description

**Pause** after producing the implementation plan and skip suggestions, and wait for user confirmation.

---

# Stage 3: Interface Design (TDD Red)

Use the Agent tool to dispatch a **tdd-guide** subagent (`subagent_type: "shipshape-skills:tdd-guide"`). Pass in: the Stage 1 implementation plan, and existing interfaces from relevant files.

The tdd-guide subagent is responsible for:
- Defining TypeScript interfaces / types based on the plan (and selected UI approach)
- Designing function signatures (parameters, return values)
- Writing no implementation — only defining the skeleton

**Pause** after output and wait for user confirmation of the interface design.

---

# Stage 4: Write Unit Tests (TDD Red)

**Iron Law: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.** Wrote code first and are adding tests after? Delete it and start over.

Use the Agent tool to dispatch a **tdd-guide** subagent (`subagent_type: "shipshape-skills:tdd-guide"`). Pass in: the Stage 1 implementation plan, the Stage 3 interface design, and the project's testing standards.

The tdd-guide subagent writes vitest unit tests based on the interface design:
- Test location: `src/tests/unit/`, mirroring `src/` structure
- Follows project testing standards
- Covers happy paths, edge cases, error handling
- Follows the Mock Three Laws (don't test mock behavior, don't add test-only methods, understand dependencies before mocking)

## Rationalization Prevention

The following excuses are **invalid** and must not be used to skip tests:

| Excuse | Rebuttal |
|--------|---------|
| "It's too simple to need tests" | Simple code also breaks, and testing simple code is extremely cheap |
| "I already manually tested it" | Manual tests leave no record, can't be re-run, can't prevent regression |
| "Adding tests after achieves the same thing" | Writing tests first asks "what should this do?"; writing after asks "what does this do?" — different mindsets |
| "Deleting code I've already written is wasteful" | Sunk cost fallacy. Keeping incorrect code is what's wasteful |
| "The test passed immediately after writing" | That means you're testing existing behavior, not a new feature — re-examine the test assertions |

## Verify RED (Mandatory)

After writing tests, **must** run `bun run test` and confirm:
1. Tests are **FAIL** (assertion failure), not **ERROR** (syntax error / import error / runtime crash)
2. Failure messages match expectations (e.g. `expected true, received false`)
3. Failure reason is "feature not yet implemented", not that the test itself is broken

- FAIL = correct Red, can proceed to next step
- ERROR = test itself has a problem, **fix the test first** before continuing

**Pause** after output and wait for user confirmation that the test intent is correct.

---

# Stage 5: Implement Feature (TDD Green)

## Pre-knowledge Check (Mandatory)

Before writing code, **must** consult the following resources to avoid repeating mistakes or violating established patterns:

1. **Cookbook cross-reference (progressive disclosure)**: Read `docs/cookbook/README.md` to find relevant module → read that module's `MOC.md` to find relevant files → only read the files you need (`business-rules.md`, `pitfalls.md`). Also check `architecture/MOC.md` for related architectural decisions.
2. **Memory feedback**: Read feedback records in memory to check for past experience relevant to this development task.
3. **Existing pattern analysis**: For files you're going to modify, first understand their existing design patterns (method naming conventions, branch handling conventions, error handling approach). New code must follow the same patterns. **Prefer extending existing methods (adding parameters or branches) over creating new methods that rewrite logic.**

> If the pre-knowledge check reveals a conflict with the plan (e.g. the cookbook documents a different approach), **pause** and report to the user; adjust the plan before implementing.

## Implementation Standards

Develop the feature code to make all tests pass:
- Follow the project's code style and naming conventions
- Minimal implementation, no over-engineering — only write the minimum code to make tests pass
- **Package version attention**: When using third-party packages, first confirm the version installed in the project (`package.json`), then look up the API docs for that version. Different major versions may have breaking changes; don't assume API usage matches training data. If Context7 MCP is available, use it to query documentation for the specific version.

## Verify GREEN (Mandatory)

Run `bun run test` and confirm:
1. All new tests **PASS**
2. **All existing tests still pass** (no regression)
3. Test output is clean, no warnings or console errors

If existing tests fail due to new code, **fix the regression before continuing**.

## Completion Check (Mandatory)

After implementation is complete, **must** go back and cross-reference the Stage 1 change list, confirming each planned item is complete:
- List all changes from the plan
- Mark each item's completion status (✅ / ❌)
- **If there are incomplete items, continue implementing until all are done** — do not proceed to the next stage
- UI changes (components, styles, i18n translations) also count; don't only do the logic layer

Follow the project's development cadence rules for confirmation granularity:
- Utilities can be batched 3–5 at a time
- Business logic: pause after writing tests
- Side effects: confirm each one

---

# Stage 5.5: Refactor (TDD Refactor)

After all tests are green, refactor:
- Remove duplicate code
- Improve naming and readability
- Extract shared helpers / utilities
- **No new features, no behavior changes**

Run `bun run test` again after refactoring to confirm all tests still pass.

This stage can be reported together with Stage 5; no extra pause needed.

---

# Stage 7: Auto-Improve Tests

Use the **auto-improve-tests** skill to iteratively improve unit tests:
- Target score: >= 9.2/10
- Maximum iterations: 5
- Early-stop condition: stop if consecutive improvement < 0.2 in two iterations
- Each iteration outputs: score, issue list, improvement actions
- **Strictly forbidden to modify production code** — only modify tests

Report the final score and iteration count after completion, then **pause** and wait for user confirmation.

---

# Stage 9: Code Review (Two-Stage Review)

Use the Agent tool to dispatch a **code-reviewer** subagent (`subagent_type: "shipshape-skills:code-reviewer"`). Pass in: the Stage 1 implementation plan, the git diff of changes in this session, and relevant cookbook content.

The code-reviewer subagent conducts a **two-stage** review:

## Stage One: Specification Compliance

Cross-reference against Stage 1's plan and confirm:
- Does the feature **fully match requirements**, no more and no less?
- Are there any missing planned items?
- Are there any extra changes beyond the plan's scope?

**Stage One must pass before entering Stage Two** — confirm direction first, then assess quality.

## Stage Two: Code Quality

- Check code quality, security, maintainability
- Flag CRITICAL / HIGH / MEDIUM issues
- Report review results

## Iterative Fix Loop

After the review results are out, if there are CRITICAL or HIGH issues, enter the fix loop:

1. **Review** — code-reviewer produces review report
2. **Fix** — modify code based on CRITICAL and HIGH issues in the report
3. **Verify** — run `bun run test` to confirm tests pass, then run code-reviewer again to confirm issues are resolved
4. **Repeat** — if there are still CRITICAL or HIGH issues, return to step 2

Loop exit conditions (either one suffices):
- code-reviewer judges as **Approve** (no CRITICAL or HIGH issues)
- User explicitly states the **current version is acceptable**

## Cookbook Cross-Reference Check (Mandatory)

New or modified code **must** be cross-referenced against `docs/cookbook/`:
- Read relevant cookbook documents (e.g. when developing the homepage module → read `module-development-guide.md`)
- Confirm new code follows the patterns and notes documented in the cookbook
- If the cookbook has documented "common mistakes" or "important notes", check each one is not violated
- If the cookbook description and actual code are inconsistent, update the cookbook
- See CLAUDE.md "Quality Gates → Cookbook Sync" three-question rule for criteria on adding new entries

## Knowledge Capture (After Review Discussion)

During code review, the user may explain why a piece of code was written a certain way (business logic, intentional design, historical reasons). When the user's explanation reveals **tacit knowledge that can't be inferred from the code**, **proactively ask the user whether to record it in the cookbook**.

Typical scenarios:
- Review flags "this looks like a bug", user explains "this is intentional, because of XXX business rule"
- Review suggests "should use approach A here", user explains "we tried A before, but switched to B because of YYY"
- Review asks "why not use a simpler approach", user explains "ZZZ library has an issue in this context"

These are all "why" knowledge that code can't show — exactly what the cookbook is for. Keep the inquiry brief with a summary of the key point:

> Should this business rule (XXX requires YYY) be recorded in the cookbook? I'll write it to `docs/cookbook/<module>/business-rules.md`.

If user agrees, write it and update `MOC.md`; if not, skip.

After completion, ask the user whether they want to commit.
