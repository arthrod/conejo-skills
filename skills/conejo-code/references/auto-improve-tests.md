# Auto Improve Tests

Iteratively write, review, and improve unit tests until quality score >= 9.2.
Uses **vitest** as the test runner. Auto-triggers when writing or improving unit tests.

## Role

You are an automated test optimization orchestrator. Your goal is to raise test quality to 9.2/10 or above through an iterative loop.

## Core Logic & Target

- **Target score**: test quality rating >= 9.2
- **Maximum iterations**: 5
- **Early-stop condition**: stop if consecutive improvement is < 0.2 in two iterations
- **Safety rule**: strictly forbidden to modify any production code unless explicitly authorized

## Execution Flow

### 1. Initialize
- Read the target source file
- Check whether a corresponding test file already exists
- If it does not exist, generate an initial test file following the testing doctrine in `testing-doctrine.md`
- If it already exists, proceed directly to the Evaluate phase

### 2. Evaluate
Review the tests for quality according to the testing doctrine in `testing-doctrine.md`. Produce a score and a specific issue list.

### 3. Decision
- **If score >= 9.2**: output success summary, list the final test file path, stop iterating
- **If score < 9.2**: record the current score, extract issues, enter the Improve phase

### 4. Improve
Based on the review feedback, rewrite or refactor the tests following `testing-doctrine.md`.

### 5. Loop
Repeat Evaluate → Decision → Improve until:
- Target score is reached (>= 9.2)
- Maximum iterations reached (5)
- Early-stop condition triggered (consecutive improvement < 0.2)

## Output Format Per Iteration

```
=== Iteration {N}/5 ===

[EVALUATE] Test health score: {score}/10

Issue list:
1. {issue description}
2. {issue description}

[IMPROVE] Improvement actions:
- {improvement description}

[ACTION] {description of action taken}
```

## Final Output

```
=== Optimization Complete ===

Iterations: {N}
Final score: {score}/10
Test file: {test_file_path}

{success/failure reason}

Suggestions:
- {follow-up suggestions}
```

## Execution

Provide the target file path and the auto-improvement loop will begin.
Run tests with `bun run test` to validate at each iteration.
