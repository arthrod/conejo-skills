---
name: testing-strategy
description: "Enforces dependency isolation, coverage, and test quality standards for Python pytest suites. Use when writing tests, fixing test failures, increasing coverage, or reviewing test quality. Triggers on: write tests, fix tests, increase coverage, test failures, mock strategy."
---

# Testing Strategy

Structured test authoring and debugging for Python projects using pytest.

## Dependency Isolation Priority

When handling dependencies in tests, follow this strict priority order:

### 1. Prefer deterministic production code
Structure logic as pure functions. Pure functions need no mocking.

### 2. Pull test utilities from the dependency itself
Before writing any mock or fake, examine how the dependency tests itself:
- **httpx**: Use `httpx.MockTransport` or `respx`/`pytest-httpx`. NEVER patch `httpx.get`/`httpx.post`.
- **OpenAI SDK (v1.x+)**: Mock at httpx transport layer. Construct responses with SDK Pydantic models (`ChatCompletion`, `Choice`, `ChatCompletionMessage`, `CompletionUsage`).
- **SQLAlchemy**: Use in-memory SQLite (`sqlite://`) as fake database engine.

### 3. Use fakes over generic mocks
For non-deterministic deps (DB, network, filesystem, clocks), prefer in-memory fakes implementing the same interface.

### 4. Use `unittest.mock` only as last resort
Mock only what is necessary. Over-mocking couples tests to implementation details.

### 5. NEVER use real non-deterministic dependencies in unit tests
Network, disk, database, wall-clock time MUST be replaced with fake or mock. Real deps belong in integration tests only.

## Debugging Failing Tests

Apply this diagnostic order:

1. **Assume the test is wrong first.** Check fixture setup, mock wiring, assertion logic, and test data. The system under test is already written; the test is newer, less-proven code.
2. **Do NOT reduce coverage to make tests pass.** Fix or rewrite the test — never delete it or comment it out. Coverage must be monotonically non-decreasing.
3. **If the test is correct and the code is wrong**, fix the code and document what the test caught.

### Common failure patterns

- **Dimension/constant mismatch**: When production code changes a constant (e.g., embedding dimensions), tests that hardcode the old value break. Fix by referencing the constant from the source class:
  ```python
  assert len(embedding) == EmbeddingService.EMBEDDING_DIMENSION
  ```
- **Mock returns wrong shape**: When a mock returns data that doesn't match current production expectations, update the mock to match.
- **Integration tests depending on external infra**: Tests calling real binaries, databases, or APIs must be skipped or faked when the infra isn't available. Use `pytest.importorskip` or `@pytest.mark.skipif`.

## Coverage Requirements

All test runs MUST produce coverage reports:

```bash
pytest --cov=<source_dir> --cov-report=term-missing --cov-branch
```

- New modules: target ≥80% line coverage, ≥70% branch coverage baseline
- Critical business logic: target ≥90% line, ≥85% branch
- State achieved coverage in working notes

### Coverage rules
- Use `--cov-fail-under=<threshold>` when a minimum is established
- Report BOTH line and branch coverage
- Never reduce coverage to fix failures

## Smoke Test (Dry Run)

After unit tests pass:
- **Web servers**: assert process starts, binds to port, returns HTTP 200 on health endpoint
- **CLI tools**: assert entrypoint executes `--help` or no-op command without error
- **Libraries**: assert public API imports and trivial call succeeds

## Test Quality Validation

When warranted, run mutation testing on critical modules:
- **Python**: `mutmut` or `cosmic-ray`
- Mutation score below 60% on critical code suggests weak assertions even with high line coverage

## Workflow

1. Read failing test output carefully
2. Identify root cause (test bug vs production bug)
3. Check if test references hardcoded values that should come from production constants
4. Fix test or production code as appropriate
5. Run full suite with coverage
6. Verify coverage is non-decreasing

<!-- cross-ref:start -->

## See also (related skills — Testing (project-level) family)

If your issue relates to:
- **audit the whole test suite — rerun coverage, stale debt** — check `testing-review` if appropriate.
- **Plate/Slate editor 3-layer strategy** — check `plate-testing-strategy` if appropriate.

<!-- cross-ref:end -->

