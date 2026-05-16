---
name: rust-author
description: Authoring & setting up Rust projects — idiomatic Rust (ownership/borrowing/cloning patterns, Result error handling, clippy config, static vs dynamic dispatch, performance, doc tests) plus project scaffolding (Cargo.toml, multi-crate workspaces, CI pipelines, rustfmt). Use when writing Rust code or starting/restructuring a Rust project.
---

# Rust — Authoring & Setup

| Concern | Section |
|---|---|
| Idiomatic Rust patterns — ownership, errors, clippy, dispatch | [Best Practices](#best-practices) |
| Scaffolding new projects — Cargo.toml, workspaces, CI, rustfmt | [Project Setup](#project-setup) |

If you have an existing project and need to write or refactor code → start at Best Practices.
If you're spinning up a new crate or workspace → start at Project Setup.

For reviewing existing Rust code (source, tests, async, FFI), see `rust-review`.

---

# Best Practices


# Rust Best Practices

Guidance for writing idiomatic, performant, and safe Rust code. This is a development skill, not a review skill -- use it when building, not reviewing.

## Quick Reference

| Topic | Key Rule | Reference |
|-------|----------|-----------|
| Ownership | Borrow by default, clone only when you need a separate owned copy | [references/coding-idioms.md](references/coding-idioms.md) |
| Clippy | Run `cargo clippy -- -D warnings` on every commit; configure workspace lints | [references/clippy-config.md](references/clippy-config.md) |
| Performance | Don't guess, measure. Profile with `--release` first | [references/performance.md](references/performance.md) |
| Generics | Static dispatch by default, dynamic dispatch when you need mixed types | [references/generics-dispatch.md](references/generics-dispatch.md) |
| Type State | Encode state in the type system when invalid operations should be compile errors | [references/type-state-pattern.md](references/type-state-pattern.md) |
| Documentation | `//` for why, `///` for what and how, `//!` for module/crate purpose | [references/documentation.md](references/documentation.md) |
| Pointers | Choose pointer types based on ownership needs and threading model | [references/pointer-types.md](references/pointer-types.md) |
| API Design | Unsurprising, flexible, obvious, constrained -- encode invariants in types | [references/api-design.md](references/api-design.md) |
| Ecosystem | Evaluate crates, pick error handling strategy, stay current | [references/ecosystem-patterns.md](references/ecosystem-patterns.md) |

## Coding Idioms

Prefer `&T` over `.clone()`, use `&str`/`&[T]` in parameters, and chain iterators instead of index-based loops. For Option/Result, use `let Ok(x) = expr else { return }` for early returns and `?` for propagation. See [references/coding-idioms.md](references/coding-idioms.md) for ownership, iterator, and import patterns.

## Error Handling

Return `Result<T, E>` for fallible operations. Use `thiserror` for library error types, `anyhow` for binaries. Propagate with `?`, never `unwrap()` outside tests. See [references/coding-idioms.md](references/coding-idioms.md) for Option/Result patterns.

## Clippy Discipline

Run `cargo clippy --all-targets --all-features -- -D warnings` on every commit. Configure workspace lints in `Cargo.toml` and use `#[expect(clippy::lint)]` (not `#[allow]`) as the standard for lint suppression -- it warns when the suppression becomes stale. See [references/clippy-config.md](references/clippy-config.md) for lint configuration and key lints.

## Performance Mindset

Always benchmark with `--release`, profile before optimizing, and avoid cloning in loops or premature `.collect()` calls. Keep small types on the stack and heap-allocate only recursive structures and large buffers. See [references/performance.md](references/performance.md) for profiling tools and allocation guidance.

## Generics and Dispatch

Use static dispatch (`impl Trait` / `<T: Trait>`) by default for zero-cost monomorphization. Switch to `dyn Trait` only for heterogeneous collections or plugin architectures, preferring `&dyn Trait` over `Box<dyn Trait>` when ownership isn't needed. In edition 2024, `-> impl Trait` captures all in-scope lifetimes by default -- use `+ use<'a, T>` for precise capture control. Prefer native `async fn` in traits over the `async-trait` crate for static dispatch. See [references/generics-dispatch.md](references/generics-dispatch.md) for dispatch trade-offs, RPIT capture rules, and async trait guidance.

## Type State Pattern

Encode valid states in the type system so invalid operations become compile errors. Use for builders with required fields, protocol state machines, and workflow pipelines. See [references/type-state-pattern.md](references/type-state-pattern.md) for implementation patterns and when to avoid.

## Documentation

Use `//` for why, `///` for what/how on public APIs, and `//!` for module purpose. Every `TODO` needs a linked issue and library crates should enable `#![deny(missing_docs)]`. Use `#[diagnostic::on_unimplemented]` to provide custom compiler errors for your public traits. See [references/documentation.md](references/documentation.md) for doc test patterns, comment conventions, and diagnostic attributes.

## API Design

Follow four principles: unsurprising (reuse standard names and traits), flexible (use generics and `impl Trait` to avoid unnecessary restrictions), obvious (encode invariants in the type system so misuse is a compile error), and constrained (expose only what you can commit to long-term). Use `#[non_exhaustive]` for types that may grow, seal traits you need to extend without breaking changes, and wrap foreign types in newtypes to control your SemVer surface. See [references/api-design.md](references/api-design.md) for builder patterns, sealed traits, and SemVer implications.

## Ecosystem Patterns

Evaluate crates by recent download trends, maintenance activity, documentation quality, and transitive dependency weight. Use `thiserror` for library error types, `anyhow` for binaries, and `eyre` when you need custom error reporters. Prefer vendoring or writing code yourself when a crate pulls heavy dependencies for a small feature. Run `cargo-deny` for license and vulnerability auditing and `cargo-udeps` to trim unused dependencies. See [references/ecosystem-patterns.md](references/ecosystem-patterns.md) for crate evaluation criteria, edition migration, and essential tooling.

## Pointer Types

Choose pointer types based on ownership and threading: `Box<T>` for single-owner heap allocation, `Rc<T>`/`Arc<T>` for shared ownership, `Cell`/`RefCell`/`Mutex`/`RwLock` for interior mutability. Use `LazyLock`/`LazyCell` (stable since 1.80) instead of `lazy_static` or `once_cell`. See [references/pointer-types.md](references/pointer-types.md) for the full single-thread vs multi-thread decision table and migration guidance.

<!-- cross-ref:start -->

## See also (related skills — Rust family)

If your issue relates to:
- **scaffold a new Rust project — Cargo.toml, workspaces, CI** — check `rust-project-setup` if appropriate.
- **review Rust source code** — check `rust-code-review` if appropriate.
- **review Rust tests specifically** — check `rust-testing-code-review` if appropriate.
- **review tokio async runtime usage, sync primitives, channels** — check `tokio-async-code-review` if appropriate.
- **review Rust FFI — type safety, memory layout, unsafe boundaries** — check `ffi-code-review` if appropriate.

<!-- cross-ref:end -->


---

# Project Setup


# Rust Project Setup

Step-by-step guidance for setting up new Rust projects with proper configuration, linting, and CI.

## Quick Reference

| Topic | Reference |
|-------|-----------|
| Cargo.toml configuration, profiles, dependencies | [references/cargo-config.md](references/cargo-config.md) |
| Workspace organization, member layout, shared deps | [references/workspace-layout.md](references/workspace-layout.md) |
| GitHub Actions CI, caching, MSRV checks | [references/ci-setup.md](references/ci-setup.md) |
| Feature flags, conditional compilation, build scripts | [references/features-conditional.md](references/features-conditional.md) |
| no_std development, embedded targets, cross-compilation | [references/no-std.md](references/no-std.md) |

## New Project Checklist

### 1. Create the Project

```shell
# Binary
cargo init my-app

# Library
cargo init --lib my-lib

# Workspace (create Cargo.toml manually)
mkdir my-workspace && cd my-workspace
```

### 2. Configure Cargo.toml

Set edition, rust-version (MSRV), and metadata:

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"
```

### 3. Set Up Linting

Add clippy and rustfmt configuration:

```toml
# Cargo.toml
[lints.clippy]
all = { level = "deny", priority = 10 }
pedantic = { level = "warn", priority = 3 }

[lints.rust]
future-incompatible = "warn"
nonstandard_style = "deny"
# unsafe_op_in_unsafe_fn is deny-by-default in edition 2024 — no need to set it
```

> **Edition 2024 lint defaults**: `unsafe_op_in_unsafe_fn` is deny by default. Unsafe operations inside `unsafe fn` require explicit `unsafe {}` blocks. The `gen` keyword is reserved — use `r#gen` if needed as an identifier.

```toml
# rustfmt.toml
edition = "2024"
reorder_imports = true
imports_granularity = "Crate"
group_imports = "StdExternalCrate"
```

### 4. Configure Profiles

```toml
[profile.release]
lto = true
codegen-units = 1
strip = true
```

### 5. Set Up CI

Add GitHub Actions workflow for check, clippy, test, and fmt. See [references/ci-setup.md](references/ci-setup.md).

### 6. Cargo.lock Policy

- **Binaries**: Commit `Cargo.lock` (reproducible builds)
- **Libraries**: Do NOT commit `Cargo.lock` (consumers resolve their own versions)
- Add to `.gitignore` for libraries: `Cargo.lock`

### 7. Documentation Setup

For library crates, enable doc lints:

```rust
// src/lib.rs
#![deny(missing_docs)]
```

Prefer `#[expect(lint)]` over `#[allow(lint)]` for temporary suppressions — it warns when the suppression becomes unnecessary:

```rust
#[expect(dead_code, reason = "used in next PR")]
fn upcoming_feature() {}
```

## Workspace vs Single Crate

| Use | When |
|-----|------|
| Single crate | Small project, CLI tool, simple library |
| Workspace | Multiple related crates, shared dependencies, separate compile targets |

Workspaces reduce compile times by sharing dependencies and build artifacts across members.

## Project Structure

### Binary

```text
my-app/
  Cargo.toml
  rustfmt.toml
  src/
    main.rs
    lib.rs      # separate logic from entry point
  tests/
    integration_test.rs
```

### Library

```text
my-lib/
  Cargo.toml
  rustfmt.toml
  src/
    lib.rs
    module_a.rs
    module_b/
      mod.rs
      types.rs
  tests/
    api_test.rs
  examples/
    basic_usage.rs
```

### Workspace

```text
my-workspace/
  Cargo.toml          # [workspace] definition
  rustfmt.toml        # shared formatting
  crates/
    core/             # shared types and logic
    api/              # HTTP server
    cli/              # command-line interface
```

## Dependency Best Practices

- Pin exact versions for binaries: `serde = "=1.0.210"`
- Use version ranges for libraries: `serde = "1"`
- Group features explicitly: `tokio = { version = "1", features = ["rt-multi-thread", "macros"] }`
- Use `[dev-dependencies]` for test-only crates
- Review `cargo tree` for duplicate versions
- Run `cargo audit` for security vulnerabilities
- Replace `once_cell`/`lazy_static` with `std::sync::LazyLock` (stable since Rust 1.80)

## Edition 2024 Migration Notes

When migrating existing projects to edition 2024:

- `unsafe fn` bodies now require explicit `unsafe {}` blocks around unsafe operations
- `extern "C" {}` blocks must be written as `unsafe extern "C" {}`
- `#[no_mangle]` and `#[export_name]` require `#[unsafe(no_mangle)]` and `#[unsafe(export_name)]`
- `gen` is a reserved keyword — rename any `gen` identifiers to `r#gen` or choose a different name
- `-> impl Trait` captures all in-scope lifetimes by default; use `+ use<'a>` for precise control
- `!` (never type) falls back to `!` instead of `()` — review match arms and diverging expressions
- Temporaries in `if let` and tail expressions drop earlier — review code holding locks or guards in these positions

Run `cargo fix --edition` to auto-fix most mechanical changes.

## Related Skills

- `beagle-rust:rust-best-practices` — idiomatic patterns and edition 2024 coding guidance
- `beagle-rust:rust-code-review` — code review covering ownership, unsafe, and trait design

<!-- cross-ref:start -->

## See also (related skills — Rust family)

If your issue relates to:
- **idiomatic Rust — ownership, errors, clippy, dispatch** — check `rust-best-practices` if appropriate.
- **review Rust source code** — check `rust-code-review` if appropriate.
- **review Rust tests specifically** — check `rust-testing-code-review` if appropriate.
- **review tokio async runtime usage, sync primitives, channels** — check `tokio-async-code-review` if appropriate.
- **review Rust FFI — type safety, memory layout, unsafe boundaries** — check `ffi-code-review` if appropriate.

<!-- cross-ref:end -->

