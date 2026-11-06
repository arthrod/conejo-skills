# Acceptance criteria — the independent measurer (canonical)

Arthur, 2026-11-06: **every plan task has acceptance criteria. ALWAYS. No exceptions.**
And each criterion is checked by an **independent measurer** of the code's behavior —
not by reading the code.

Authored once here; referenced by writing-plans, executing-plans,
subagent-driven-development, requesting-code-review, verification-before-completion,
finishing-a-development-branch and every conejo-* skill.

## The rule

1. **Every task carries an `Acceptance criteria` block.** A task without one is not a
   task: writing-plans' self-review rejects it; executing-plans and SDD refuse to start
   it until it has one (write it, ledger a `Ruling:` that you did).
2. **Each criterion states an observable behavior** of the finished software or
   artifact (a CLI, an endpoint, a screen, a notebook, a figure, a dataset, a document)
   — what a person or a script sees from OUTSIDE the code.
3. **Each criterion names its independent measurer:** a command, probe, click-flow,
   diff, or metric that someone who never read the diff can run and get pass/fail.
   Reading the code is review. Review is not measurement.
4. **Measurers are red-green too.** Run the measurer BEFORE implementing and record
   that it fails (or that the thing it measures does not exist yet). Run it AFTER and
   record that it passes. Both outputs go in the ledger line.
5. **Reviewers run the measurers.** A task review or final review that reports
   "cannot verify from diff" on an acceptance criterion is incomplete — the reviewer
   runs the measurer and reports its output. "The diff looks like it does X" is not
   evidence that it does X.
6. **At least one measurer per task is independent of the implementer's own unit
   tests.** TDD's failing-then-passing test is necessary, but it is the author grading
   their own carrot count. The independent measurer is the second grader.

## Why not just code review?

Code review answers "does this code look like it does what we want?" A measurer answers
"does the software DO what we want?" They disagree more often than anyone likes: the
mock that hides the real API shape, the env var that is read on the wrong machine, the
migration that passed in SQLite and fails in Postgres, the figure that reproduces only
with yesterday's seed. Review catches intent; measurement catches reality. We need both.

## Measurer catalog (pick by kind; combine freely)

| Kind of work | Independent measurer | Criterion line looks like |
|---|---|---|
| CLI | run the binary on a fixture; compare stdout / stderr / exit code; golden file diff | `AC1: parsing fixtures/a.docx yields 12 clauses. Measure: \`diff <(mytool parse fixtures/a.docx) fixtures/a.expected\` → empty, exit 0.` |
| HTTP API | `curl` + `jq -e` against a running, seeded server | `AC2: POST /v1/redline returns 201 and an id. Measure: \`curl -s -o /tmp/r.json -w '%{http_code}' …\` → 201 and \`jq -e .id /tmp/r.json\`.` |
| Web UI | agent-browser click-flow + screenshot; browser console clean (conejo-frontend) | `AC3: clicking Save shows the "Saved" toast. Measure: the click-flow in tests/e2e/save.md passes; screenshot attached; console has 0 errors.` |
| Library / module | a black-box test in a separate file that imports only the public surface; a property test; a mutation check (revert the fix → test fails) | `AC4: \`sortClauses\` is stable for equal keys. Measure: \`pnpm vitest run tests/blackbox/sort.test.ts\` → pass; it fails on \`git stash\`.` |
| Data pipeline | row counts, checksums, schema validation on the output; sample diff vs golden | `AC5: output has 1,164 rows and sha256 …. Measure: \`uv run python check.py out.parquet\` prints OK.` |
| Performance | a timing / memory threshold measured by a script over N runs (p95) | `AC6: p95 < 200 ms over 50 runs. Measure: \`uv run python bench.py\` prints p95.` |
| Research / analysis | reproduce the number or figure from a clean run with a fixed seed; tolerance stated; dataset checksum pinned | `AC7: table 2 row 3 = 0.84 ± 0.01. Measure: \`uv run python repro.py --seed 7\` prints 0.84x.` |
| Docs / README | link checker; every documented command actually runs (doctest-style) | `AC8: every \`\`\`bash block in README runs. Measure: \`scripts/run-readme.sh\` exits 0.` |
| Config / infra | dry-run shows the expected resource; a smoke request after deploy | `AC9: deploy serves /health 200. Measure: \`curl -sf https://…/health\`.` |
| Package / release | the published artifact installs clean in an empty env and its entry point runs | `AC10: \`uvx mytool --version\` in a fresh venv prints the tag.` |

## Plan format (writing-plans)

````markdown
### Task N: [Component]

**Files:** …
**Interfaces:** …
**Acceptance criteria:**
- AC1: <observable behavior>. Measure: `<command or probe>` → expected `<output / exit code / screenshot>`.
- AC2: <observable behavior>. Measure: …
**Stack:** branch `feat/<plan>-<N>-<slug>` on `<previous task's branch or main>`

- [ ] **Step 0: Run each AC's measurer — record that it fails (RED, black box)**
- [ ] **Step 1: Write the failing test** …
- [ ] …
- [ ] **Step N-1: Run each AC's measurer — record that it passes (GREEN, black box)**
- [ ] **Step N: Commit, `gh stack add` / `gh stack push`**
````

A measurer that cannot be run before the code exists (the binary isn't built yet) is
recorded as "absent" in Step 0 — that is a legitimate RED.

## Ledger format (executing-plans / SDD)

```
Task <N>: complete (commits <a7>..<b7>, tests: <cmd> → <result>, AC: AC1 ✓ "<measurer output>", AC2 ✓ "<…>")
```

An AC with ✗ is an open finding; the task is not complete.

## Review format (requesting-code-review / task reviewer / final reviewer)

The reviewer's report has a section `### Acceptance criteria — measured` listing each
AC, the command it ran, and the output. Missing section = incomplete review; re-dispatch.
