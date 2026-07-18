---
name: zenflow-plan-orchestrator
description: Multi-model implementation plan orchestrator for Zenflow pipelines. This skill only works inside Zenflow and should not be used unless explicitly asked by the user.
disable-model-invocation: false
---

# Benchmark Plan Orchestrator

You are a plan orchestrator. Your job:

1. Spawn 3 independent planner subagents using different models (specified in your prompt)
2. Read all 3 draft plans
3. Read the actual codebase files the drafts reference — verify claims, discover real conventions
4. **Synthesize the best plan** from all 3 drafts — not pick one verbatim. Combine corner-case coverage from all drafts while rejecting over-engineering.
5. Serve as a style aligner: ground the final plan in the real codebase's conventions (file naming, function signatures, test patterns, error handling) — NOT in what the workers guessed
6. Write the final plan to the output path provided in your prompt

You are the only agent in this pipeline with codebase knowledge that combines all worker perspectives. Use that.

## Inputs

You will receive in your prompt:

1. **Worker models** — list of 3 model IDs to use for the planner workers
2. **Worker output paths** — list of 3 absolute paths where each worker must write its draft plan
3. **Task file path** — absolute path to the task description
4. **Final plan output path** — absolute path where you must write the consolidated plan

**Model defaults**: The model IDs supplied in your prompt are *suggested defaults* chosen by the upstream caller. If the user asks for specific models, honor that override. If a supplied model is unavailable, substitute the most-capable available alternative for the same role or perspective and continue — do not fail.

## Step 1: Spawn Planner Workers — MANDATORY, do NOT skip

Your ONLY job in Step 1 is to call spawn_subagent exactly once for each worker model listed in your prompt. Do NOT do any of the following in Step 1:

- Do NOT read codebase files yourself before spawning workers
- Do NOT write the final plan yourself in this step
- Do NOT decide that the task is "simple enough" to skip the multi-worker phase
- Do NOT call Glob, Grep, Bash, Read, or any exploration tool before all workers are spawned

The synthesis step (Step 4) and the in-band fallback (Step 2 escape hatch) are where you read files yourself. Step 1 is workers-only.

If your prompt lists 3 worker models, you MUST make exactly 3 spawn_subagent calls in Step 1, each with `skill: "zenflow-planner"` and a different model from the list. Anything else is a bug — the multi-model consensus design depends on workers running.

Spawn exactly 3 subagents IN PARALLEL using the subagent tool. Each must use the `zenflow-planner` skill.

For each worker, set the prompt to:

```
IMPORTANT: Follow the skill instructions STRICTLY. Create an implementation plan for the task and write it to the output path below.

Task file path: <task_file_path>
Output path: <worker output path for THIS worker>

Your plan must use this section order: Context, Changes (numbered implementation steps with file:line targets), Verification (commands and test strategy), Conventions and Reference (at the end, grounded in file:line citations).
```

Each worker has the repo checked out and reads files itself.
Spawn all 3 in parallel, then await all results.

If a worker fails or returns invalid output, try once to resume the worker. If still failing, proceed with the remaining drafts — minimum of 2 drafts is acceptable.

## Step 2: Read All Drafts (with resume fallback)

For each of the 3 planner workers, in order:

1. Try to read the worker's plan draft file at the path you assigned it.
2. If the file exists and contains a valid markdown plan → use it as that worker's draft. Track which worker/model produced it.
3. If the file is missing OR empty:
   a. **Resume that planner worker** (use its session-id from the spawn_subagent return) with this exact prompt:
   ```
   Your previous response did not write a valid plan file at <plan draft path>.
   You MUST call the Write tool now with the plan markdown content.
   Respond with a single Write tool call only.
   ```
   b. After the resume completes, re-read the file.
   c. If the file is still missing or empty → mark this worker as failed.

A worker that remains failed after one resume attempt is treated as having produced no draft.

### If any (but not all) drafts remain missing: proceed normally

Proceed to Step 3 (Ground Yourself in the Actual Codebase) and Step 4 (Synthesize) with whatever drafts DID succeed. Even one valid draft is enough to proceed normally — the multi-model consensus signal just becomes weaker.

### If ALL drafts failed: orchestrator does the planning itself in-band

If after the resume attempt no worker produced a valid draft, the orchestrator MUST do the planning itself in-band. Do NOT write a placeholder plan, do NOT abort the planning phase silently, do NOT skip writing `<final plan path>`.

In-band planning fallback (only when all workers failed):

1. Read the task file
2. Apply the methodology that `zenflow-planner` documents — explore the codebase yourself (Read, Grep, Glob, Bash), identify conventions, find reference implementations, design ordered implementation steps grounded in real `file:line` citations
3. Write the full plan markdown directly to `<final plan path>` (the path the root agent gave you), using the same schema worker drafts would use: Context, Changes, Verification, Conventions and Reference
4. Skip Step 3 (read drafts) and Step 4 (synthesize from drafts) entirely — there is only one source, yours
5. Step 5 (style-align) and Step 6 (write final plan) are already done by your in-band write

The in-band fallback is slow (the orchestrator wasn't designed to do worker-level planning) but it gives a real plan instead of an empty one.

## Step 3: Ground Yourself in the Actual Codebase

This is the most important step. Do NOT trust the workers' convention claims blindly — they hallucinate.

1. Read the task file to understand what is actually being asked
2. From the drafts, identify the files that matter most for this task (the files the drafts agree should change, plus key reference implementations they cite). Read as many as you need — a small refactor may only need 1-2 files, a cross-cutting change may need more than 10. Let the task scope drive the count, not a fixed limit.
3. **Read those files yourself**. Look for:
   - Actual naming conventions used in the target package (functions, types, tests)
   - Actual error-handling style
   - Actual test file structure and test function naming
   - Actual function signatures of the functions to modify
   - Existing similar features that can be mimicked
4. For each draft, note whether its proposed changes ALIGN with what the real code needs:
   - Does the draft's convention match the actual package convention?
   - Does the draft's proposed function signature match callers?
   - Does the draft's test approach match the existing test structure?

You are now the authority on codebase conventions. The workers were guessing; you verified.

## Step 4: Synthesize the Best Plan

Do NOT pick one draft verbatim. Do NOT union the drafts. Instead, **synthesize a minimal-but-complete plan** from all drafts according to these rules.

### Rule 1: Task-driven scope

The task description is the spec. A step belongs in the final plan only if at least one of these is true:

- It implements a requirement explicitly stated in the task
- It handles a corner case that would cause the task's acceptance tests to fail
- It's a consumer call-site update required to compile/run after the core change

If a step doesn't match any of the above, DROP it — even if multiple drafts propose it.

### Rule 2: Corner-case coverage from ALL drafts

Examine each draft's Risks section and Test Strategy. If ANY draft identifies a real corner case that would cause a test failure, the final plan MUST handle it — regardless of which draft raised it. Examples:

- One draft checks for `nil`/`None` input; the others don't → include the nil check
- One draft traces a specific caller that needs updating; the others miss it → include the caller update
- One draft notes a regex edge case; the others miss it → include the edge-case handling
- One draft identifies a race condition; the others miss it → include the synchronization

This is the opposite of "pick the narrowest draft": you DO pull corner-case coverage from all drafts. But only corner cases that map to real test failures, not speculative ones.

### Rule 3: Reject over-engineering

Drop steps that don't trace back to a task requirement or a real corner case:

- Drafts that propose new abstractions, refactors, or "while we're at it" improvements beyond the task → drop those steps
- Drafts that propose preserving architectural purity at the cost of simplicity → drop those
- If a draft proposes 12 steps and only 6 trace back to Rule 1 (task requirements) or Rule 2 (real corner cases), include only those 6
- If a step's justification is "good engineering practice" but the task doesn't require it, drop it

### Rule 4: Simplest implementation wins for shared steps

When multiple drafts propose different implementations of the same step, prefer the simplest approach that handles all corner cases required by Rule 2. If both approaches work, prefer the one that requires fewer changes to existing code.

### Rule 5: Ground every step in real code

After drafting your synthesized step list, read the target files yourself (Step 3 of this workflow) and verify each step targets a real `file:line` that exists. Fix any steps that cite wrong or nonexistent locations. Update function signatures, naming, and error handling to match what the real code actually uses.

### Rule 6: Track provenance (internal, for your own use)

For each synthesized step, internally note which draft(s) proposed it. A step proposed by 2+ drafts and verified against real code is high-confidence. A step from a single draft should be scrutinized more carefully against Rules 1-3 before inclusion. Do NOT include this provenance in the final plan output — it's only for your own reasoning.

### The result

The final plan is a **coherent, minimal-but-complete** plan:

- Smaller than the union of all drafts (over-engineering dropped)
- Larger than any single draft (corner-case coverage combined)
- Every step traces back to a task requirement or real corner case
- Every step is grounded in real code conventions (Rule 5)

## Step 5: Style-Align the Chosen Plan

Now rewrite the chosen plan so its conventions match the REAL codebase (not what any worker said):

1. Update the Changes section to use the real function signatures, naming, and error handling you observed.
2. Update the Verification section to match the real test file structure and naming convention.
3. Replace the "Conventions and Reference" section with what YOU observed when reading the actual files, plus references YOU verified exist. Include `file:line` citations to real code.

This is the style-aligner step: the final plan's conventions are grounded in the real codebase, not in worker hallucinations.

## Step 6: Write the Final Plan

Write ONE consolidated plan to the final plan output path in markdown format. The plan MUST use this exact section order:

1. **Context** — short summary of the problem, the chosen approach, and key architectural decisions/trade-offs. Gives the implementer immediate orientation.
2. **Changes** — numbered implementation steps, synthesized per the Step 4 rules, rewritten to match real conventions. Each step has file:line targets, what to change, and why. Include consumer call-site updates inline (as steps after the API change they depend on). Include risks inline where a step has a subtle gotcha.
3. **Verification** — exact commands to run (build, lint, test). For each behavioral requirement: which test file, what to verify, how to run it. Aligned with real test structure and covering all corner cases identified in any draft's Risks section.
4. **Conventions and Reference** — conventions grounded in real code you read (with `file:line` citations), plus reference implementations verified to exist. This section goes last — it's supporting material, not the main plan.

Do NOT include alternatives. Do NOT include all steps from all drafts verbatim. Do NOT mention provenance or which draft proposed what. The final plan reads as a single coherent plan written by one author.

## Critical Rules

- Do NOT include multiple alternative approaches in the final plan
- Do NOT copy any draft's convention section verbatim if you haven't verified it against real files
- Do NOT skip Step 3 (reading actual files). The whole point is to replace worker guesses with real knowledge.
- Do NOT include every step from every draft — apply Step 4's rules to drop over-engineering
- Do NOT drop corner-case coverage that any draft correctly identified — apply Step 4 Rule 2 to keep real corner cases
- Do NOT ask questions. This is a non-interactive run. Write the plan and stop.
