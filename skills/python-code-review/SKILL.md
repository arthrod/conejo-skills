---
name: python-code-review
description: Reviews Python code AND pytest test code — type safety, async patterns, error handling, common mistakes, plus pytest setup correctness (test file location, conftest.py wiring, asyncio_mode), fixtures, parametrize, mocking. Use when reviewing .py or test_*.py files. Triggers on python code review, pytest review, type hint review, async review, fixture review.
---

# Python & Pytest Code Review

## Setup Sanity Checklist — run FIRST when reviewing tests

Before reviewing individual test files, verify the test infrastructure is correct. A misconfigured pytest setup makes every downstream review pointless.

- [ ] **Test file locations match the project's chosen layout.**
      Either `tests/` (top-level, mirrors `src/`) OR co-located `test_*.py` next to source. Mixed layouts cause discovery surprises. Check `pyproject.toml` `[tool.pytest.ini_options] testpaths = [...]` — if missing, ask the user which layout they want.
- [ ] **`conftest.py` is at the right level(s).**
      One at `tests/` (or repo root) for shared fixtures. Additional `conftest.py` files only inside subdirectories that need scoped fixtures. Multiple top-level `conftest.py` files is a bug. An empty `conftest.py` purely to "make discovery work" usually means `testpaths`/`rootdir` is wrong — fix the root cause.
- [ ] **`asyncio_mode = "auto"`** is set in `pyproject.toml` if the project uses async tests, OR every async test is decorated with `@pytest.mark.asyncio`. Mixing both produces silent skips. Prefer `auto` for new projects.
- [ ] **Plugins declared** in `pyproject.toml` match what tests import (`pytest-asyncio`, `pytest-mock`, `pytest-xdist`, `pytest-cov`, `pytest-recording`/VCR). If a test uses a plugin's marker but the plugin isn't installed, pytest emits a warning, not an error — tests pass with the marker silently ignored.
- [ ] **`pythonpath`** is set in `pyproject.toml` if using `src/` layout. Without it, `from mypackage import ...` fails in tests unless the package is installed editable. Prefer `[tool.pytest.ini_options] pythonpath = ["src"]`.
- [ ] **Markers registered** in `pyproject.toml` (`markers = ["slow", "integration", ...]`). Unregistered markers emit `PytestUnknownMarkWarning` which masks real warnings.
- [ ] **`addopts`** is sensible. `--strict-markers` + `--strict-config` should be on. `-p no:cacheprovider` only if cache is genuinely a problem.
- [ ] **Coverage config (`pyproject.toml` `[tool.coverage.*]`)** excludes `tests/`, `__main__.py`, `if TYPE_CHECKING:` blocks.

If ANY checklist item fails, fix the setup first. Then review individual tests.

### Minimal good `pyproject.toml` pytest stanza

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
asyncio_mode = "auto"
addopts = [
    "--strict-markers",
    "--strict-config",
    "-ra",
]
markers = [
    "slow: tests that take >1s",
    "integration: hits real external services",
]
```

---

## Quick Reference

### Python (source code)

| Issue Type | Reference |
|------------|-----------|
| Indentation, line length, whitespace, naming | [references/pep8-style.md](references/pep8-style.md) |
| Missing/wrong type hints, Any usage | [references/type-safety.md](references/type-safety.md) |
| Blocking calls in async, missing await | [references/async-patterns.md](references/async-patterns.md) |
| Bare except, missing context, logging | [references/error-handling.md](references/error-handling.md) |
| Mutable defaults, print statements | [references/common-mistakes.md](references/common-mistakes.md) |

### Pytest (test code)

| Issue Type | Reference |
|------------|-----------|
| async def test_*, AsyncMock, await patterns | [references/async-testing.md](references/async-testing.md) |
| conftest.py, factory fixtures, scope, cleanup | [references/fixtures.md](references/fixtures.md) |
| @pytest.mark.parametrize, DRY patterns | [references/parametrize.md](references/parametrize.md) |
| AsyncMock tracking, patch patterns, when to mock | [references/mocking.md](references/mocking.md) |

---

## Review Checklist

### Python — PEP8 Style
- [ ] 4-space indentation (no tabs)
- [ ] Line length ≤79 characters (≤72 for docstrings/comments)
- [ ] Two blank lines around top-level definitions, one within classes
- [ ] Imports grouped: stdlib → third-party → local (blank line between groups)
- [ ] No whitespace inside brackets or before colons/commas
- [ ] Naming: `snake_case` for functions/variables, `CamelCase` for classes, `UPPER_CASE` for constants
- [ ] Inline comments separated by at least two spaces

### Python — Type Safety
- [ ] Type hints on all function parameters and return types
- [ ] No `Any` unless necessary (with comment explaining why)
- [ ] Proper `T | None` syntax (Python 3.10+)

### Python — Async Patterns
- [ ] No blocking calls (`time.sleep`, `requests`) in async functions
- [ ] Proper `await` on all coroutines

### Python — Error Handling
- [ ] No bare `except:` clauses
- [ ] Specific exception types with context
- [ ] `raise ... from` to preserve stack traces

### Python — Common Mistakes
- [ ] No mutable default arguments
- [ ] Using `logger` not `print()` for output
- [ ] f-strings preferred over `.format()` or `%`

### Pytest — Test Functions
- [ ] Test functions are `async def test_*` for async code under test
- [ ] AsyncMock used for async dependencies, not Mock
- [ ] All async mocks and coroutines are awaited
- [ ] Test isolation (no shared mutable state between tests)

### Pytest — Fixtures
- [ ] Fixtures in `conftest.py` for shared setup
- [ ] Fixture scope appropriate (function, class, module, session)
- [ ] Yield fixtures have proper cleanup in `finally` block
- [ ] Factory fixtures used for parameterized objects, not module-scoped mutable state

### Pytest — Parametrize
- [ ] `@pytest.mark.parametrize` for similar test cases
- [ ] No duplicated test logic across multiple test functions
- [ ] Parametrized IDs are readable (use `ids=` when defaults are noisy)

### Pytest — Mocking
- [ ] Mocks track calls properly (`assert_called_once_with`)
- [ ] `patch()` targets correct location (where USED, not where defined)
- [ ] No mocking of internals that should be tested
- [ ] Real database / real LLM for integration tests when feasible — don't mock what you can run

---

## Valid Patterns (Do NOT Flag)

These are intentional and correct:

- **Type annotation vs type assertion** — Annotations declare types but are not runtime assertions; don't confuse with missing validation
- **Using `Any` when interacting with untyped libraries** — Required when external libraries lack type stubs
- **Empty `__init__.py` files** — Valid for package structure, no code required
- **`noqa` comments** — Valid when linter rule doesn't apply to specific case
- **Using `cast()` after runtime type check** — Correct pattern to inform type checker of narrowed type
- **`pytest.fixture` without `scope="function"`** — `function` is the default; not explicit is fine
- **Test files without docstrings on each test** — A descriptive test name is sufficient

## Context-Sensitive Rules

Only flag these issues when the specific conditions apply:

| Issue | Flag ONLY IF |
|-------|--------------|
| Generic exception handling | Specific exception types are available and meaningful |
| Unused variables | Variable lacks `_` prefix AND isn't used in f-strings, logging, or debugging |
| Mocking a function | A real implementation could be used instead without flakiness |

---

## When to Load References

- Reviewing code formatting/style → `pep8-style.md`
- Reviewing function signatures → `type-safety.md`
- Reviewing `async def` functions → `async-patterns.md`
- Reviewing try/except blocks → `error-handling.md`
- General Python review → `common-mistakes.md`
- Reviewing async test functions → `async-testing.md`
- Reviewing fixtures or conftest.py → `fixtures.md`
- Reviewing similar test cases → `parametrize.md`
- Reviewing mocks and patches → `mocking.md`

---

## Review Questions

**Python source:**
1. Does the code follow PEP8 formatting (indentation, line length, whitespace)?
2. Are imports properly grouped (stdlib → third-party → local)?
3. Do names follow conventions (snake_case, CamelCase, UPPER_CASE)?
4. Are all function signatures fully typed?
5. Are async functions truly non-blocking?
6. Do exceptions include meaningful context?
7. Are there any mutable default arguments?

**Pytest tests:**
1. Did the Setup Sanity Checklist pass? (If not, fix infrastructure FIRST.)
2. Are all async functions tested with `async def test_*`?
3. Are fixtures properly scoped with appropriate cleanup?
4. Can similar test cases be parametrized to reduce duplication?
5. Are mocks tracking calls and used at the right locations?

---

## Before Submitting Findings

Load and follow [review-verification-protocol](../review-verification-protocol/SKILL.md) before reporting any issue.

<!-- cross-ref:start -->

## See also (related skills — Code review family)

If your issue relates to:
- **CodeRabbit-powered review (default)** — check `code-review` if appropriate.
- **auto-apply CodeRabbit review comments** — check `autofix` if appropriate.
- **Rust source review** — check `rust-code-review` if appropriate.
- **Rust test review** — check `rust-testing-code-review` if appropriate.
- **tokio async review** — check `tokio-async-code-review` if appropriate.
- **Rust FFI review** — check `ffi-code-review` if appropriate.
- **Deep Agents code review** — check `deepagents-code-review` if appropriate.
- **SQLAlchemy 2.0 review** — check `sqlalchemy-code-review` if appropriate.

<!-- cross-ref:end -->

