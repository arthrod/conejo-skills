---
name: rust-review
description: Comprehensive Rust code review across four lenses — source code (ownership, borrowing, lifetimes, errors, trait design, unsafe, common mistakes), tests (unit, integration, async testing, mocking, property-based), tokio async (task management, sync primitives, channels), and FFI (extern blocks, #[repr(C)], string handling, unsafe boundaries, bindgen). Use when reviewing any .rs file or audit-style review request.
---

# Rust — Comprehensive Review

Four review lenses. Pick the section that matches what you're reviewing — apply multiple if the file spans concerns (e.g. an async tokio service with FFI bindings).

| Lens | Section |
|---|---|
| Source code — ownership, errors, trait design, unsafe | [Source review](#source-review) |
| Test code — unit, integration, async, mocking, proptest | [Test review](#test-review) |
| tokio async — task mgmt, sync primitives, channels | [Tokio async review](#tokio-async-review) |
| FFI — extern, repr(C), strings, callbacks, unsafe boundary | [FFI review](#ffi-review) |

For writing or setting up Rust (not reviewing it), see `rust-author`.

---

# Source review


# Rust Code Review

## Review Workflow

Follow this sequence to avoid false positives and catch edition-specific issues:

1. **Check `Cargo.toml`** — Note the Rust edition (2018, 2021, 2024) and MSRV if set. Edition 2024 introduces breaking changes to unsafe semantics, RPIT lifetime capture, temporary scoping, and `!` type fallback. This determines which patterns apply. Check workspace structure if present.
2. **Check dependencies** — Note key crates (thiserror vs anyhow, tokio features, serde features). These inform which patterns are expected.
3. **Scan changed files** — Read full functions, not just diffs. Many Rust bugs hide in ownership flow across a function.
4. **Check each category** — Work through the checklist below, loading references as needed.
5. **Verify before reporting** — Load beagle-rust:review-verification-protocol before submitting findings.

## Output Format

Report findings as:

```text
[FILE:LINE] ISSUE_TITLE
Severity: Critical | Major | Minor | Informational
Description of the issue and why it matters.
```

## Quick Reference

| Issue Type | Reference |
|------------|-----------|
| Ownership transfers, borrowing, lifetimes, clone traps, iterators | [references/ownership-borrowing.md](references/ownership-borrowing.md) |
| Lifetime variance, covariance/invariance, memory regions | [references/lifetime-variance.md](references/lifetime-variance.md) |
| Result/Option handling, thiserror, anyhow, error context, Error trait | [references/error-handling.md](references/error-handling.md) |
| Async pitfalls, Send/Sync bounds, runtime blocking | [references/async-concurrency.md](references/async-concurrency.md) |
| Send/Sync semantics, atomics, memory ordering, lock patterns | [references/concurrency-primitives.md](references/concurrency-primitives.md) |
| Type layout, alignment, repr, PhantomData, generics vs dyn Trait | [references/types-layout.md](references/types-layout.md) |
| Unsafe code, API design, derive patterns, clippy patterns | [references/common-mistakes.md](references/common-mistakes.md) |
| Safety contracts, raw pointers, MaybeUninit, soundness, Miri | [references/unsafe-deep.md](references/unsafe-deep.md) |

> For development guidance on performance, pointer types, type state, clippy config, iterators, generics, and documentation, use the `beagle-rust:rust-best-practices` skill.

## Review Checklist

### Ownership and Borrowing
- [ ] No unnecessary `.clone()` to silence the borrow checker (hiding design issues)
- [ ] No `.clone()` inside loops — prefer `.cloned()` or `.copied()` on iterators
- [ ] No cloning to avoid lifetime annotations (take ownership explicitly or restructure)
- [ ] References have appropriate lifetimes (not overly broad `'static` when shorter lifetime works)
- [ ] **Edition 2024**: RPIT (`-> impl Trait`) captures all in-scope lifetimes by default; use `+ use<'a>` for precise capture control
- [ ] `&str` preferred over `String`, `&[T]` over `Vec<T>` in function parameters
- [ ] `impl AsRef<T>` or `Into<T>` used for flexible API parameters
- [ ] No dangling references or use-after-move
- [ ] Interior mutability (`Cell`, `RefCell`, `Mutex`) used only when shared mutation is genuinely needed
- [ ] Small types (≤24 bytes) derive `Copy` and are passed by value
- [ ] `Cow<'_, T>` used when ownership is ambiguous
- [ ] Iterator chains preferred over index-based loops for collection transforms
- [ ] No premature `.collect()` — pass iterators directly when the consumer accepts them
- [ ] `.sum()` preferred over `.fold()` for summation (compiler optimizes better)
- [ ] `_or_else` variants used when fallbacks involve allocation
- [ ] **Edition 2024**: `if let` temporaries drop at end of the `if let` — code relying on temporaries living through the else branch needs restructuring
- [ ] **Edition 2024**: `Box<[T]>` implements `IntoIterator` — prefer direct iteration over `into_vec()` first

### Error Handling
- [ ] `Result<T, E>` used for recoverable errors, not `panic!`/`unwrap`/`expect`
- [ ] Error types provide context (thiserror with `#[error("...")]` or manual `Display`)
- [ ] `?` operator used with proper `From` implementations or `.map_err()`
- [ ] `unwrap()` / `expect()` only in tests, examples, or provably-safe contexts
- [ ] Error variants are specific enough to be actionable by callers
- [ ] `anyhow` used in applications, `thiserror` in libraries (or clear rationale for alternatives)
- [ ] `_or_else` variants used when fallbacks involve allocation (`ok_or_else`, `unwrap_or_else`)
- [ ] `let-else` used for early returns on failure (`let Ok(x) = expr else { return ... }`)
- [ ] `inspect_err` used for error logging, `map_err` for error transformation

### Traits and Types
- [ ] Traits are minimal and cohesive (single responsibility)
- [ ] `derive` macros appropriate for the type (`Clone`, `Debug`, `PartialEq` used correctly)
- [ ] Newtypes used to prevent primitive obsession (e.g., `struct UserId(Uuid)` not bare `Uuid`)
- [ ] `From`/`Into` implementations are lossless and infallible; `TryFrom` for fallible conversions
- [ ] Sealed traits used when external implementations shouldn't be allowed
- [ ] Default implementations provided where they make sense
- [ ] `Send + Sync` bounds verified for types shared across threads
- [ ] `#[diagnostic::on_unimplemented]` used on public traits to provide clear error messages when users forget to implement them

### Unsafe Code
- [ ] `unsafe` blocks have safety comments explaining invariants
- [ ] `unsafe` is minimal — only the truly unsafe operation is inside the block
- [ ] Safety invariants are documented and upheld by surrounding safe code
- [ ] No undefined behavior (null pointer deref, data races, invalid memory access)
- [ ] `unsafe` trait implementations justify why the contract is upheld
- [ ] **Edition 2024**: `unsafe fn` bodies use explicit `unsafe {}` blocks around unsafe ops (`unsafe_op_in_unsafe_fn` is deny)
- [ ] **Edition 2024**: `extern "C" {}` blocks written as `unsafe extern "C" {}`
- [ ] **Edition 2024**: `#[no_mangle]` and `#[export_name]` written as `#[unsafe(no_mangle)]` and `#[unsafe(export_name)]`

### Naming and Style
- [ ] Types are `PascalCase`, functions/methods `snake_case`, constants `SCREAMING_SNAKE_CASE`
- [ ] Modules use `snake_case`
- [ ] `is_`, `has_`, `can_` prefixes for boolean-returning methods
- [ ] Builder pattern methods take and return `self` (not `&mut self`) for chaining
- [ ] Public items have doc comments (`///`)
- [ ] `#[must_use]` on functions where ignoring the return value is likely a bug
- [ ] Imports ordered: std → external crates → workspace → crate/super
- [ ] `#[expect(clippy::...)]` preferred over `#[allow(...)]` for lint suppression

### Performance
> Detailed guidance: `beagle-rust:rust-best-practices` skill (references/performance.md)
- [ ] No unnecessary allocations in hot paths (prefer `&str` over `String`, `&[T]` over `Vec<T>`)
- [ ] `collect()` type is specified or inferable
- [ ] Iterators preferred over indexed loops for collection transforms
- [ ] `Vec::with_capacity()` used when size is known
- [ ] No redundant `.to_string()` / `.to_owned()` chains
- [ ] No intermediate `.collect()` when passing iterators directly works
- [ ] `.sum()` preferred over `.fold()` for summation
- [ ] Static dispatch (`impl Trait`) used over dynamic (`dyn Trait`) unless flexibility required

### Clippy Configuration
> Detailed guidance: `beagle-rust:rust-best-practices` skill (references/clippy-config.md)
- [ ] Workspace-level lints configured in `Cargo.toml` (`[workspace.lints.clippy]` or `[lints.clippy]`)
- [ ] `#[expect(clippy::lint)]` used over `#[allow(...)]` — warns when suppression becomes stale
- [ ] Justification comment present when suppressing any lint
- [ ] Key lints enforced: `redundant_clone`, `large_enum_variant`, `needless_collect`, `perf` group
- [ ] `cargo clippy --all-targets --all-features -- -D warnings` passes
- [ ] Doc lints enabled for library crates (`missing_docs`, `broken_intra_doc_links`)

### Type State Pattern
> Detailed guidance: `beagle-rust:rust-best-practices` skill (references/type-state-pattern.md)
- [ ] `PhantomData<State>` used for zero-cost compile-time state machines (not runtime enums/booleans)
- [ ] State transitions consume `self` and return new state type (prevents reuse of old state)
- [ ] Only applicable methods available per state (invalid operations are compile errors)
- [ ] Pattern used where it adds safety value (builders with required fields, connection states, workflows)
- [ ] Not overused for trivial state (simple enums are fine when runtime flexibility needed)

## Severity Calibration

### Critical (Block Merge)
- `unsafe` code with unsound invariants or undefined behavior
- Use-after-free or dangling reference patterns
- `unwrap()` on user input or external data in production code
- Data races (concurrent mutation without synchronization)
- Memory leaks via circular `Arc<Mutex<...>>` without weak references

### Major (Should Fix)
- Errors returned without context (bare `return err` equivalent)
- `.clone()` masking ownership design issues in hot paths
- Missing `Send`/`Sync` bounds on types used across threads
- `panic!` for recoverable errors in library code
- Overly broad `'static` lifetimes hiding API design issues

### Minor (Consider Fixing)
- Missing doc comments on public items
- `String` parameter where `&str` or `impl AsRef<str>` would work
- Derive macros missing for types that should have them
- Unused feature flags in `Cargo.toml`
- Suboptimal iterator chains (multiple allocations where one suffices)

### Informational (Note Only)
- Suggestions to introduce newtypes for domain modeling
- Refactoring ideas for trait design
- Performance optimizations without measured impact
- Suggestions to add `#[must_use]` or `#[non_exhaustive]`

## When to Load References

- Reviewing ownership, borrows, lifetimes, clone traps → ownership-borrowing.md
- Reviewing lifetime variance, covariance/invariance, multiple lifetime params → lifetime-variance.md
- Reviewing Result/Option handling, error types, Error trait impls → error-handling.md
- Reviewing async code, tokio usage, task management → async-concurrency.md
- Reviewing Send/Sync, atomics, memory ordering, mutexes, lock patterns → concurrency-primitives.md
- Reviewing type layout, alignment, repr, PhantomData, generics vs dyn → types-layout.md
- Reviewing unsafe code, API design, derive macros, clippy patterns → common-mistakes.md
- Reviewing safety contracts, raw pointers, MaybeUninit, soundness → unsafe-deep.md
- Reviewing performance, pointer types, type state, generics, iterators, documentation → `beagle-rust:rust-best-practices` skill

## Valid Patterns (Do NOT Flag)

These are acceptable Rust patterns — reporting them wastes developer time:

- **`.clone()` in tests** — Clarity over performance in test code
- **`unwrap()` in tests and examples** — Acceptable where panicking on failure is intentional
- **`Box<dyn Error>` in simple binaries** — Not every application needs custom error types
- **`String` fields in structs** — Owned data in structs is correct; `&str` fields require lifetime parameters
- **`#[allow(dead_code)]` during development** — Common during iteration
- **`todo!()` / `unimplemented!()` in new code** — Valid placeholder during active development
- **`.expect("reason")` with clear message** — Self-documenting and acceptable for invariants
- **`use super::*` in test modules** — Standard pattern for `#[cfg(test)]` modules
- **Type aliases for complex types** — `type Result<T> = std::result::Result<T, MyError>` is idiomatic
- **`impl Trait` in return position** — Zero-cost abstraction, standard pattern
- **Turbofish syntax** — `collect::<Vec<_>>()` is idiomatic when type inference needs help
- **`_` prefix for intentionally unused variables** — Compiler convention
- **`#[expect(clippy::...)]` with justification** — Self-cleaning lint suppression
- **`Arc::clone(&arc)`** — Explicit Arc cloning is idiomatic and recommended
- **`std::sync::Mutex` for short critical sections in async** — Tokio docs recommend this
- **`for` loops over iterators** — When early exit or side effects are needed
- **`async fn` in trait definitions** — Stable since 1.75; `async-trait` crate only needed for `dyn Trait` or pre-1.75 MSRV
- **`LazyCell` / `LazyLock` from std** — Stable since 1.80; replaces `once_cell` and `lazy_static` for new code
- **`+ use<'a, T>` precise capture syntax** — Edition 2024 syntax for controlling RPIT lifetime capture

## Context-Sensitive Rules

Only flag these issues when the specific conditions apply:

| Issue | Flag ONLY IF |
|-------|--------------|
| Missing error context | Error crosses module boundary without context |
| Unnecessary `.clone()` | In hot path or repeated call, not test/setup code |
| Missing doc comments | Item is `pub` and not in a `#[cfg(test)]` module |
| `unwrap()` usage | In production code path, not test/example/provably-safe |
| Missing `Send + Sync` | Type is actually shared across thread/task boundaries |
| Overly broad lifetime | A shorter lifetime would work AND the API is public |
| Missing `#[must_use]` | Function returns a value that callers commonly ignore |
| Stale `#[allow]` suppression | Should be `#[expect]` for self-cleaning lint management |
| Missing `Copy` derive | Type is ≤24 bytes with all-Copy fields and used frequently |
| **Edition 2024**: `!` type fallback | Match on `Result<T, !>` or diverging expressions where `()` fallback was assumed — `!` now falls back to `!` not `()` |
| **Edition 2024**: `r#gen` identifier | Code uses `gen` as an identifier — must be `r#gen` in edition 2024 (reserved keyword) |

## Before Submitting Findings

Load and follow `beagle-rust:review-verification-protocol` before reporting any issue.

<!-- cross-ref:start -->

## See also (related skills — Code review family)

If your issue relates to:
- **CodeRabbit-powered review (default)** — check `code-review` if appropriate.
- **auto-apply CodeRabbit review comments** — check `autofix` if appropriate.
- **Python + pytest review (type safety, async, fixtures)** — check `python-code-review` if appropriate.
- **Rust test review** — check `rust-testing-code-review` if appropriate.
- **tokio async review** — check `tokio-async-code-review` if appropriate.
- **Rust FFI review** — check `ffi-code-review` if appropriate.
- **Deep Agents code review** — check `deepagents-code-review` if appropriate.
- **SQLAlchemy 2.0 review** — check `sqlalchemy-code-review` if appropriate.

<!-- cross-ref:end -->


---

# Test review


# Rust Testing Code Review

## Review Workflow

1. **Check Rust edition** — Note edition in `Cargo.toml` (2021 vs 2024). Edition 2024 changes temporary scoping in `if let` and tail expressions, and makes `#[expect]` the preferred lint suppression
2. **Check test organization** — Unit tests in `#[cfg(test)]` modules, integration tests in `tests/` directory
3. **Check async test setup** — `#[tokio::test]` for async tests, proper runtime configuration. Check for `async-trait` on mocks that could use native `async fn` in traits
4. **Check assertions** — Meaningful messages, correct assertion type. Review `if let` assertions for edition 2024 temporary scope changes
5. **Check test isolation** — No shared mutable state between tests, proper setup/teardown. Prefer `LazyLock` over `lazy_static!`/`once_cell` for shared fixtures
6. **Check coverage patterns** — Error paths tested, edge cases covered

## Output Format

Report findings as:

```text
[FILE:LINE] ISSUE_TITLE
Severity: Critical | Major | Minor | Informational
Description of the issue and why it matters.
```

## Quick Reference

| Issue Type | Reference |
|------------|-----------|
| Unit tests, assertions, naming, snapshots, rstest, doc tests, `#[expect]`, `LazyLock` fixtures, tail expression scope | [references/unit-tests.md](references/unit-tests.md) |
| Integration tests, async testing, fixtures, test databases, native `async fn` mocks, `if let` temporary scope | [references/integration-tests.md](references/integration-tests.md) |
| Fuzzing, property-based testing, Miri, Loom, benchmarking, compile_fail, custom harness, mocking strategies | [references/advanced-testing.md](references/advanced-testing.md) |

## Review Checklist

### Test Structure
- [ ] Unit tests in `#[cfg(test)] mod tests` within source files
- [ ] Integration tests in `tests/` directory (one file per module or feature)
- [ ] `use super::*` in test modules to access parent module items
- [ ] Test function names describe the scenario: `test_<function>_<scenario>_<expected>`
- [ ] Tests are independent — no reliance on execution order

### Async Tests
- [ ] `#[tokio::test]` used for async test functions
- [ ] `#[tokio::test(flavor = "multi_thread")]` when testing multi-threaded behavior
- [ ] No `block_on` inside async tests (use `.await` directly)
- [ ] Test timeouts set for tests that could hang
- [ ] Mock traits use native `async fn` instead of `async-trait` crate (stable since Rust 1.75)

### Assertions
- [ ] `assert_eq!` / `assert_ne!` used for value comparisons (better error messages than `assert!`)
- [ ] Custom messages on assertions that aren't self-documenting
- [ ] `matches!` macro used for enum variant checking
- [ ] Error types checked with `matches!` or pattern matching, not string comparison
- [ ] One assertion per test where practical (easier to diagnose failures)
- [ ] `if let` assertions reviewed for edition 2024 temporary scope — temporaries in conditions drop earlier, may invalidate borrows
- [ ] Tail expression returns reviewed for edition 2024 — temporaries in tail expressions drop before local variables

### Mocking and Test Doubles
- [ ] Traits used as seams for dependency injection (not concrete types)
- [ ] Mock implementations kept minimal — only what the test needs
- [ ] No mocking of types you don't own (wrap external dependencies behind your own trait)
- [ ] Test fixtures as helper functions, not global state
- [ ] `std::sync::LazyLock` used for shared test fixtures instead of `lazy_static!` or `once_cell` (stable since Rust 1.80)

### Error Path Testing
- [ ] `Result::Err` variants tested, not just happy paths
- [ ] Specific error variants checked (not just "is error")
- [ ] `#[should_panic]` used sparingly — prefer `Result`-returning tests

### Lint Suppression in Tests
- [ ] `#[expect(lint)]` used instead of `#[allow(lint)]` for test-specific suppressions (stable since Rust 1.81)
- [ ] Justification comment on every `#[expect]` or `#[allow]` in test code
- [ ] Stale `#[allow]` attributes migrated to `#[expect]` for self-cleaning behavior

### Test Naming
- [ ] Test names read like sentences describing behavior (not `test_happy_path`)
- [ ] Related tests grouped in nested `mod` blocks for organization
- [ ] Test names follow pattern: `<function>_should_<behavior>_when_<condition>`

### Snapshot Testing
- [ ] `cargo insta` used for complex structural output (JSON, YAML, HTML, CLI output)
- [ ] Snapshots are small and focused (not huge objects)
- [ ] Redactions used for unstable fields (timestamps, UUIDs)
- [ ] Snapshots committed to git in `snapshots/` directory
- [ ] Simple values use `assert_eq!`, not snapshots

### Parametrized Testing
- [ ] `rstest` used to avoid duplicated test functions for similar inputs
- [ ] `#[rstest]` with `#[case::name]` attributes for descriptive parametrized tests
- [ ] `#[fixture]` used for shared test setup when multiple tests need same construction
- [ ] Parametrized tests still have descriptive case names (not just `#[case(1)]`)
- [ ] Combined with async: `#[rstest] #[tokio::test]` for async parametrized tests

### Doc Tests
- [ ] Public API functions have `/// # Examples` with runnable code
- [ ] Doc tests serve as both documentation and correctness checks
- [ ] Hidden setup lines prefixed with `#` to keep examples clean
- [ ] `cargo test --doc` passes (nextest doesn't run doc tests)

## Severity Calibration

### Critical
- Tests that pass but don't actually verify behavior (assertions on wrong values)
- Shared mutable state between tests causing flaky results
- Missing error path tests for security-critical code

### Major
- `#[should_panic]` without `expected` message (catches any panic, including wrong ones)
- `unwrap()` in test setup that hides the real failure location
- Tests that depend on execution order
- `if let` with inline temporary in assertion that breaks under edition 2024 temporary scoping
- `async-trait` on mock traits when native `async fn` in traits is available and project targets edition 2024

### Minor
- Missing assertion messages on complex comparisons
- `assert!(x == y)` instead of `assert_eq!(x, y)` (worse error messages)
- Test names that don't describe the scenario
- Redundant setup code that could be extracted to a helper
- `#[allow]` used where `#[expect]` would provide self-cleaning suppression
- `lazy_static!` or `once_cell` used for test fixtures when `LazyLock` is available

### Informational
- Suggestions to add property-based tests via `proptest` or `quickcheck`
- Suggestions to add snapshot testing for complex output
- Coverage improvement opportunities

## Valid Patterns (Do NOT Flag)

- **`unwrap()` / `expect()` in tests** — Panicking on unexpected errors is the correct test behavior
- **`use super::*` in test modules** — Standard pattern for accessing parent items
- **`#[allow(dead_code)]` on test helpers** — Helper functions may not be used in every test
- **`clone()` in tests** — Clarity over performance
- **Large test functions** — Integration tests can be long; extracting helpers isn't always clearer
- **`assert!` for boolean checks** — Fine when the expression is clearly boolean (`.is_some()`, `.is_empty()`)
- **Multiple assertions testing one logical behavior** — Sometimes one behavior needs multiple checks
- **`unwrap()` on `Result`-returning test functions** — Propagating with `?` is also fine but not required
- **`async-trait` on mock traits requiring `dyn` dispatch** — Native `async fn` in traits doesn't support `dyn Trait`; `async-trait` is still needed there
- **`#[expect]` with justification on test helpers** — Self-cleaning lint suppression is correct in test code
- **`LazyLock` for expensive shared test fixtures** — Thread-safe lazy init is appropriate for test globals

## Before Submitting Findings

Load and follow `beagle-rust:review-verification-protocol` before reporting any issue.

<!-- cross-ref:start -->

## See also (related skills — Code review family)

If your issue relates to:
- **CodeRabbit-powered review (default)** — check `code-review` if appropriate.
- **auto-apply CodeRabbit review comments** — check `autofix` if appropriate.
- **Python + pytest review (type safety, async, fixtures)** — check `python-code-review` if appropriate.
- **Rust source review** — check `rust-code-review` if appropriate.
- **tokio async review** — check `tokio-async-code-review` if appropriate.
- **Rust FFI review** — check `ffi-code-review` if appropriate.
- **Deep Agents code review** — check `deepagents-code-review` if appropriate.
- **SQLAlchemy 2.0 review** — check `sqlalchemy-code-review` if appropriate.

<!-- cross-ref:end -->


---

# Tokio async review


# Tokio Async Code Review

## Review Workflow

1. **Check Cargo.toml** — Note tokio feature flags (`full`, `rt-multi-thread`, `macros`, `sync`, etc.). Missing features cause confusing compile errors.
2. **Check runtime setup** — Is `#[tokio::main]` or manual runtime construction used? Multi-thread vs current-thread?
3. **Scan for blocking** — Search for `std::fs`, `std::net`, `std::thread::sleep`, CPU-heavy loops in async functions.
4. **Check channel usage** — Match channel type to communication pattern (mpsc, broadcast, oneshot, watch).
5. **Check sync primitives** — Verify correct mutex type, proper guard lifetimes, no deadlock potential.

## Output Format

Report findings as:

```text
[FILE:LINE] ISSUE_TITLE
Severity: Critical | Major | Minor | Informational
Description of the issue and why it matters.
```

## Quick Reference

| Issue Type | Reference |
|------------|-----------|
| Task spawning, JoinHandle, structured concurrency | [references/task-management.md](references/task-management.md) |
| Mutex, RwLock, Semaphore, Notify, Barrier | [references/sync-primitives.md](references/sync-primitives.md) |
| mpsc, broadcast, oneshot, watch channel patterns | [references/channels.md](references/channels.md) |
| Pin, cancellation, Future internals, select!, blocking bridge | [references/pinning-cancellation.md](references/pinning-cancellation.md) |

## Review Checklist

### Runtime Configuration
- [ ] Tokio features in Cargo.toml match actual usage
- [ ] Runtime flavor matches workload (`multi_thread` for I/O-bound, `current_thread` for simpler cases)
- [ ] `#[tokio::test]` used for async tests (not manual runtime construction)
- [ ] Worker thread count configured appropriately for production

### Task Management
- [ ] `spawn` return values (`JoinHandle`) are tracked, not silently dropped
- [ ] `spawn_blocking` used for CPU-heavy or synchronous I/O operations
- [ ] Tasks respect cancellation (via `CancellationToken`, `select!`, or shutdown channels)
- [ ] `JoinError` (task panic or cancellation) is handled, not just unwrapped
- [ ] `tokio::select!` branches are cancellation-safe
- [ ] Native `async fn` in traits used instead of `async-trait` crate where possible (stable since Rust 1.75)
- [ ] RPIT lifetime capture reviewed in async contexts — `-> impl Future` now captures all in-scope lifetimes in edition 2024

### Sync Primitives
- [ ] `tokio::sync::Mutex` used when lock is held across `.await`; `std::sync::Mutex` for short non-async sections
- [ ] No mutex guard held across await points (deadlock risk)
- [ ] `Semaphore` used for limiting concurrent operations (not ad-hoc counters)
- [ ] `RwLock` used when read-heavy workload (many readers, infrequent writes)
- [ ] `Notify` used for simple signaling (not channel overhead)
- [ ] `std::sync::LazyLock` used instead of `once_cell::sync::Lazy` or `lazy_static!` for runtime-initialized singletons (stable since Rust 1.80)
- [ ] `if let` lock guard patterns reviewed for edition 2024 temporary scoping — temporaries drop earlier, may change borrow validity

### Channels
- [ ] Channel type matches pattern: mpsc for back-pressure, broadcast for fan-out, oneshot for request-response, watch for latest-value
- [ ] Bounded channels have appropriate capacity (not too small = deadlock, not too large = memory)
- [ ] `SendError` / `RecvError` handled (indicates other side dropped)
- [ ] Broadcast `Lagged` errors handled (receiver fell behind)
- [ ] Channel senders dropped when done to signal completion to receivers

### Timer and Sleep
- [ ] `tokio::time::sleep` used instead of `std::thread::sleep`
- [ ] `tokio::time::timeout` wraps operations that could hang
- [ ] `tokio::time::interval` used correctly (`.tick().await` for periodic work)

## Severity Calibration

### Critical
- Blocking I/O (`std::fs::read`, `std::net::TcpStream`) in async context without `spawn_blocking`
- Mutex guard held across `.await` point (deadlock potential)
- `std::thread::sleep` in async function (blocks runtime thread)
- Unbounded channel where back-pressure is needed (OOM risk)

### Major
- `JoinHandle` silently dropped (lost errors, zombie tasks)
- Missing `select!` cancellation safety consideration
- Wrong mutex type (std vs tokio) for the use case
- Missing timeout on network/external operations

### Minor
- `tokio::spawn` for trivially small async blocks (overhead > benefit)
- Overly large channel buffer without justification
- Manual runtime construction where `#[tokio::main]` suffices
- `std::sync::Mutex` where contention is high enough to benefit from tokio's async mutex

### Informational
- Suggestions to use `tokio-util` utilities (e.g., `CancellationToken`)
- Tower middleware patterns for service composition
- Structured concurrency with `JoinSet`
- Migration from `async-trait` crate to native `async fn` in traits
- Migration from `once_cell` / `lazy_static` to `std::sync::LazyLock`
- Using `#[expect(lint)]` instead of `#[allow(lint)]` for self-cleaning suppression

## Valid Patterns (Do NOT Flag)

- **`std::sync::Mutex` for short critical sections** — tokio docs recommend this when no `.await` is inside the lock
- **`tokio::spawn` without explicit join** — Valid for background tasks with proper shutdown signaling
- **Unbuffered channel capacity of 1** — Valid for synchronization barriers
- **`#[tokio::main(flavor = "current_thread")]` in simple binaries** — Not every app needs multi-thread runtime
- **`clone()` on `Arc<T>` before `spawn`** — Required for moving into tasks, not unnecessary cloning
- **Large broadcast channel capacity** — Valid when lagged errors are expensive (event sourcing)
- **Native `async fn` in traits without `async-trait`** — Stable since 1.75; the crate is still valid for `dyn` dispatch cases
- **`+ use<'a>` on `-> impl Future` returns** — Correct edition 2024 precise capture syntax to limit lifetime capture
- **`#[expect(clippy::type_complexity)]` on complex async types** — Self-cleaning alternative to `#[allow]`, warns when suppression is no longer needed

## Before Submitting Findings

Load and follow `beagle-rust:review-verification-protocol` before reporting any issue.

<!-- cross-ref:start -->

## See also (related skills — Code review family)

If your issue relates to:
- **CodeRabbit-powered review (default)** — check `code-review` if appropriate.
- **auto-apply CodeRabbit review comments** — check `autofix` if appropriate.
- **Python + pytest review (type safety, async, fixtures)** — check `python-code-review` if appropriate.
- **Rust source review** — check `rust-code-review` if appropriate.
- **Rust test review** — check `rust-testing-code-review` if appropriate.
- **Rust FFI review** — check `ffi-code-review` if appropriate.
- **Deep Agents code review** — check `deepagents-code-review` if appropriate.
- **SQLAlchemy 2.0 review** — check `sqlalchemy-code-review` if appropriate.

<!-- cross-ref:end -->


---

# FFI review


# FFI Code Review

## Review Workflow

1. **Check Cargo.toml** -- Note Rust edition (2024 has breaking changes to extern blocks and unsafe attributes), `build-dependencies` (bindgen, cc, pkg-config), `crate-type` (`cdylib`, `staticlib`), and `links` key
2. **Check build.rs** -- Verify link directives (`cargo:rustc-link-lib`, `cargo:rustc-link-search`), bindgen configuration, and C source compilation
3. **Check extern blocks** -- Verify calling conventions, symbol declarations, and safety annotations
4. **Check type layout** -- Every type crossing FFI must be `#[repr(C)]` or a primitive FFI type
5. **Check string and pointer handling** -- CStr/CString usage, null checks, ownership transfers
6. **Check callbacks** -- `extern "C" fn` pointers, panic safety across FFI boundary
7. **Verify before reporting** -- Load `beagle-rust:review-verification-protocol` before submitting findings

## Output Format

Report findings as:

```text
[FILE:LINE] ISSUE_TITLE
Severity: Critical | Major | Minor | Informational
Description of the issue and why it matters.
```

## Quick Reference

| Issue Type | Reference |
|------------|-----------|
| C-to-Rust type mapping, repr(C) layout, enums, opaque types | [references/type-mapping.md](references/type-mapping.md) |
| Safe wrappers, ownership transfer, callbacks, build.rs, testing | [references/safety-patterns.md](references/safety-patterns.md) |

## Review Checklist

### extern Blocks and Calling Conventions
- [ ] Foreign function declarations use `extern "C"` (explicit, not bare `extern`)
- [ ] **Edition 2024**: `extern "C" {}` blocks written as `unsafe extern "C" {}`
- [ ] Functions exposed to C use `extern "C" fn` (not default Rust calling convention)
- [ ] Calling convention matches the foreign library (`"C"`, `"system"` for Win32 API)
- [ ] `#[link(name = "...")]` specifies the correct library name
- [ ] `#[link(name = "...", kind = "static")]` used when statically linking

### Symbol Management
- [ ] Exported functions use `#[no_mangle]` to preserve symbol names
- [ ] **Edition 2024**: `#[no_mangle]` written as `#[unsafe(no_mangle)]`
- [ ] **Edition 2024**: `#[export_name = "..."]` written as `#[unsafe(export_name = "...")]`
- [ ] `#[link_name = "..."]` used when Rust name differs from C symbol
- [ ] Exported items are `pub` (only public `#[no_mangle]` symbols appear in library output)

### Type Layout
- [ ] Every struct/union crossing FFI has `#[repr(C)]` -- Rust's default layout is undefined
- [ ] Primitive types use `std::ffi` / `std::os::raw` equivalents (`c_int`, `c_char`, `c_void`)
- [ ] No bare `i32` where C uses `int` -- use `c_int` (width varies by platform)
- [ ] Quirky C types like `__be32` use byte arrays (`[u8; 4]`), not Rust integers
- [ ] Enums crossing FFI use `#[repr(C)]` or `#[repr(u8)]`/`#[repr(u32)]` with explicit discriminants
- [ ] C-style bitflag enums use a newtype around an integer (or `bitflags` crate), not a Rust enum
- [ ] `#[non_exhaustive]` on enums representing C enumerations that may gain new values

### String Handling
- [ ] C strings use `CStr` (borrowed) or `CString` (owned), never `&str` or `String`
- [ ] `CString::new()` result is checked for interior null bytes (returns `Err` on `\0`)
- [ ] `CString` outlives any `*const c_char` pointer derived from it via `.as_ptr()`
- [ ] Incoming `*const c_char` validated with `CStr::from_ptr()` inside `unsafe`
- [ ] No assumption that C strings are valid UTF-8 -- use `to_str()` which returns `Result`
- [ ] OS paths use `OsStr`/`OsString` and `CStr`, not `&str`

### Ownership and Allocation
- [ ] Clear ownership contract: who allocates, who frees
- [ ] Rust-allocated memory freed by Rust (`Box::from_raw`), C-allocated freed by C
- [ ] `Box::into_raw` / `Box::from_raw` paired correctly for heap transfers
- [ ] `Vec::into_raw_parts` used when passing arrays to C (pointer + length + capacity)
- [ ] Destructor functions exposed for every opaque Rust type given to C
- [ ] No `Drop` running on C-allocated memory (and vice versa)

### Callbacks
- [ ] Callback types are `extern "C" fn(...)`, not closures or `fn(...)`
- [ ] Callbacks use `std::panic::catch_unwind` to prevent panics from unwinding across FFI
- [ ] Callback context passed as `*mut c_void` with safe reconstruction at call site
- [ ] `Option<extern "C" fn(...)>` used for nullable function pointers (niche optimization)

### Bindgen and Build Scripts
- [ ] Bindgen output reviewed for correctness (auto-generated types may need adjustment)
- [ ] `-sys` crate pattern used for raw bindings, separate crate for safe wrappers
- [ ] `build.rs` uses `cargo:rustc-link-lib` and `cargo:rustc-link-search` correctly
- [ ] `links` key in `Cargo.toml` prevents duplicate linking of the same native library
- [ ] Platform-specific bindings generated per-build (not checked in for a single platform)

### Safety Documentation
- [ ] Every `unsafe` block has a `// SAFETY:` comment explaining invariants
- [ ] Every public FFI wrapper function documents safety requirements
- [ ] **Edition 2024**: `unsafe fn` bodies use explicit `unsafe {}` blocks around unsafe ops

## Severity Calibration

### Critical (Block Merge)
- Missing `#[repr(C)]` on types crossing FFI boundary (undefined memory layout)
- Wrong string handling: `&str`/`String` where `CStr`/`CString` required
- Ownership confusion: freeing C-allocated memory with Rust's allocator (or vice versa)
- Panic unwinding across FFI boundary without `catch_unwind`
- Using Rust enum for C bitflags (invalid discriminant = undefined behavior)
- Passing closure where `extern "C" fn` pointer required

### Major (Should Fix)
- Missing safety documentation on `unsafe` blocks or public FFI functions
- No null pointer check on incoming `*const T` / `*mut T` before dereferencing
- `CString` dropped before its pointer is used by C (dangling pointer)
- Missing `#[link(name = "...")]` causing link failures on some platforms
- **Edition 2024**: `extern` block not marked `unsafe extern`
- **Edition 2024**: `#[no_mangle]` not wrapped in `#[unsafe(...)]`

### Minor (Consider Fixing)
- Using `i32` instead of `c_int` for C `int` (correct on most platforms but not portable)
- Missing `#[non_exhaustive]` on enums mapping to extensible C enumerations
- Verbose manual bindings where bindgen would be more maintainable
- Checked-in bindings without platform guards

### Informational
- Suggestions to split raw bindings into a `-sys` crate
- Suggestions to add opaque wrapper types for distinct `*mut c_void` pointers
- Suggestions to use `Option<NonNull<T>>` for nullable pointers

## Valid Patterns (Do NOT Flag)

- **`unsafe extern "C" {}` in edition 2024** -- correct form for foreign declarations
- **`#[unsafe(no_mangle)]` in edition 2024** -- correct form for symbol export
- **`Option<extern "C" fn(...)>` for nullable callbacks** -- niche optimization guaranteed
- **`Option<NonNull<T>>` for nullable pointers** -- zero-cost nullable pointer pattern
- **`*mut c_void` for opaque C types** -- standard when internal layout is irrelevant
- **Distinct empty structs wrapping `c_void` for type-safe opaque pointers** -- prevents pointer confusion
- **`CStr::from_bytes_with_nul_unchecked` with compile-time literal** -- safe when literal is known null-terminated
- **`extern "C-unwind"` for controlled unwinding** -- valid per RFC 2945
- **`include!(concat!(env!("OUT_DIR"), "/bindings.rs"))` in bindgen crates** -- standard pattern
- **`Box::into_raw` / `Box::from_raw` pairs for ownership transfer** -- correct pattern when paired

## Before Submitting Findings

Load and follow `beagle-rust:review-verification-protocol` before reporting any issue.

<!-- cross-ref:start -->

## See also (related skills — Code review family)

If your issue relates to:
- **CodeRabbit-powered review (default)** — check `code-review` if appropriate.
- **auto-apply CodeRabbit review comments** — check `autofix` if appropriate.
- **Python + pytest review (type safety, async, fixtures)** — check `python-code-review` if appropriate.
- **Rust source review** — check `rust-code-review` if appropriate.
- **Rust test review** — check `rust-testing-code-review` if appropriate.
- **tokio async review** — check `tokio-async-code-review` if appropriate.
- **Deep Agents code review** — check `deepagents-code-review` if appropriate.
- **SQLAlchemy 2.0 review** — check `sqlalchemy-code-review` if appropriate.

<!-- cross-ref:end -->

